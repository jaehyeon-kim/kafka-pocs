import os

from pyflink.common import Row
from pyflink.table import EnvironmentSettings, TableEnvironment, DataTypes
from pyflink.table.expressions import col
from pyflink.table.udf import AggregateFunction, udaf

BOOTSTRAP_SERVERS = os.getenv("BOOTSTRAP_SERVERS", "localhost:9093")
# https://nightlies.apache.org/flink/flink-docs-release-1.16/docs/connectors/table/kafka/
FLINK_SQL_CONNECTOR_KAFKA = "flink-sql-connector-kafka-1.16.0.jar"

env_settings = EnvironmentSettings.in_streaming_mode()
table_env = TableEnvironment.create(env_settings)
# https://nightlies.apache.org/flink/flink-docs-release-1.16/docs/dev/python/dependency_management/
kafka_jar = os.path.join(os.path.abspath(os.path.dirname(__file__)), FLINK_SQL_CONNECTOR_KAFKA)
table_env.get_config().set("pipeline.jars", f"file://{kafka_jar}")

## create kafka source table
table_env.execute_sql(
    f"""
    CREATE TABLE input (
        kk VARCHAR,
        v VARCHAR
    ) WITH (
        'connector' = 'kafka',
        'topic' = 'aggregations-input-topic',
        'properties.bootstrap.servers' = '{BOOTSTRAP_SERVERS}',
        'properties.group.id' = 'source-demo',
        'scan.startup.mode' = 'earliest-offset',
        'key.format' = 'raw',
        'key.fields' = 'kk',
        'value.format' = 'raw',
        'value.fields-include' = 'EXCEPT_KEY'
    )
    """
)
tbl = table_env.from_path("input")
print("\ncreate kafka source table")
tbl.print_schema()


class MyAggregateFunction(AggregateFunction):
    def get_value(self, accumulator):
        return Row(accumulator[0], accumulator[1], accumulator[2])

    def create_accumulator(self):
        return Row(0, 0, "")

    def accumulate(self, accumulator, row):
        accumulator[0] += 1
        accumulator[1] += len(row.v)
        accumulator[2] = accumulator[2] + " " + row.v

    def retract(self, accumulator, row):
        accumulator[0] -= 1
        accumulator[1] -= len(row.v)
        accumulator[2] -= accumulator[2].split(" ")[: len(accumulator[2].split(" ")) - 1]

    def merge(self, accumulator, accumulators):
        for other_acc in accumulators:
            accumulator[0] += other_acc[0]
            accumulator[1] += len(other_acc[1])
            accumulator[2] += accumulator[2] + " " + other_acc[2]

    def get_accumulator_type(self):
        return DataTypes.ROW(
            [DataTypes.FIELD("kk", DataTypes.STRING()), DataTypes.FIELD("v", DataTypes.STRING())]
        )

    def get_result_type(self):
        return DataTypes.ROW(
            [
                DataTypes.FIELD("a", DataTypes.BIGINT()),
                DataTypes.FIELD("b", DataTypes.BIGINT()),
                DataTypes.FIELD("c", DataTypes.STRING()),
            ]
        )


## aggregation transformations
func = MyAggregateFunction()
agg = udaf(
    func,
    result_type=func.get_result_type(),
    accumulator_type=func.get_accumulator_type(),
    name=str(func.__class__.__name__),
)
res = (
    tbl.group_by(col("kk"))
    .aggregate(agg.alias("wc", "cc", "w"))
    .select(col("kk"), col("wc"), col("cc"), col("w"))
)
print("\naggregation transformations")
res.print_schema()

## create print sink table
table_env.execute_sql(
    f"""
    CREATE TABLE print (
        kk VARCHAR,
        wc BIGINT,
        cc BIGINT,
        w VARCHAR
    ) WITH (
        'connector' = 'print'
    )
    """
)


## create kafka sink table
table_env.execute_sql(
    f"""
    CREATE TABLE output (
        kk VARCHAR,
        wc BIGINT,
        cc BIGINT,
        w VARCHAR,
        PRIMARY KEY (kk) NOT ENFORCED
    ) WITH (
        'connector' = 'upsert-kafka',
        'topic' = 'aggregations-output-topic',
        'properties.bootstrap.servers' = '{BOOTSTRAP_SERVERS}',
        'key.format' = 'raw',
        'key.fields-prefix' = 'k',
        'value.format' = 'json',
        'value.json.fail-on-missing-field' = 'false',
        'value.fields-include' = 'EXCEPT_KEY'
    )
    """
)

# ## insert into sink tables
statement_set = table_env.create_statement_set()
statement_set.add_insert("print", res)
statement_set.add_insert("output", res)
statement_set.execute().wait()
