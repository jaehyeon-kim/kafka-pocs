import os

from pyflink.common import Row
from pyflink.table import EnvironmentSettings, TableEnvironment, DataTypes
from pyflink.table.expressions import col
from pyflink.table.udf import udf, udtf

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
        k VARCHAR,
        v VARCHAR
    ) WITH (
        'connector' = 'kafka',
        'topic' = 'stateless-transformations-input-topic',
        'properties.bootstrap.servers' = '{BOOTSTRAP_SERVERS}',
        'properties.group.id' = 'source-demo',
        'scan.startup.mode' = 'earliest-offset',
        'key.format' = 'raw',
        'key.fields' = 'k',
        'value.format' = 'raw',
        'value.fields-include' = 'EXCEPT_KEY'
    )
    """
)
tbl = table_env.from_path("input")
print("\ncreate kafka source table")
tbl.print_schema()

## stateless transformations
# 1. branch and filter
atbl = tbl.where(col("v").left(1).lower_case == "a")
otbl = tbl.where(col("v").left(1).lower_case != "a")


# 2. flat_map - duplicate records
@udtf(result_types=[DataTypes.STRING(), DataTypes.STRING()])
def dup(x: Row) -> Row:
    for i, r in enumerate([x, x]):
        yield r.k, r.v.upper() if i == 0 else r.v.lower()


atbl = atbl.flat_map(dup).rename_columns(col("f0").alias("k"), col("f1").alias("v"))
print("\n2. flat_map - duplicate records")
atbl.print_schema()


# 3. map key to upper
@udf(
    result_type=DataTypes.ROW(
        [DataTypes.FIELD("f0", DataTypes.STRING()), DataTypes.FIELD("f1", DataTypes.STRING())]
    )
)
def upper(x: Row) -> Row:
    return Row(x.f0.upper(), x.f1)


atbl = atbl.map(upper)
print("\n3. map key to upper")
atbl.print_schema()

# 4. merge
mtbl = atbl.union_all(otbl)
print("\n4. merge")
mtbl.print_schema()

## create print sink table
table_env.execute_sql(
    f"""
    CREATE TABLE print (
        k VARCHAR,
        v VARCHAR
    ) WITH (
        'connector' = 'print'
    )
    """
)


## create kafka sink table
table_env.execute_sql(
    f"""
    CREATE TABLE output (
        k VARCHAR,
        v VARCHAR
    ) WITH (
        'connector' = 'kafka',
        'topic' = 'stateless-transformations-output-topic',
        'properties.bootstrap.servers' = '{BOOTSTRAP_SERVERS}',
        'key.format' = 'raw',
        'key.fields' = 'k',
        'value.format' = 'raw',
        'value.fields-include' = 'EXCEPT_KEY'
    )
    """
)

## insert into sink tables
statement_set = table_env.create_statement_set()
statement_set.add_insert("print", mtbl)
statement_set.add_insert("output", mtbl)
statement_set.execute().wait()
