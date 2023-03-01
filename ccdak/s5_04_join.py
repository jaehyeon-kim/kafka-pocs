import os

from pyflink.table import EnvironmentSettings, TableEnvironment

####
#### pyflink.util.exceptions.TableException: org.apache.flink.table.api.TableException: Processing time Window Join is not supported yet.
####    - retry with event time, need to create dedicated producer???
####

BOOTSTRAP_SERVERS = os.getenv("BOOTSTRAP_SERVERS", "localhost:9093")
# https://nightlies.apache.org/flink/flink-docs-release-1.16/docs/connectors/table/kafka/
FLINK_SQL_CONNECTOR_KAFKA = "flink-sql-connector-kafka-1.16.0.jar"

env_settings = EnvironmentSettings.in_streaming_mode()
table_env = TableEnvironment.create(env_settings)
# https://nightlies.apache.org/flink/flink-docs-release-1.16/docs/dev/python/dependency_management/
kafka_jar = os.path.join(os.path.abspath(os.path.dirname(__file__)), FLINK_SQL_CONNECTOR_KAFKA)
table_env.get_config().set("pipeline.jars", f"file://{kafka_jar}")

## create kafka source tables
table_env.execute_sql(
    f"""
    CREATE TABLE tbl_left (
        kk VARCHAR,
        v VARCHAR,
        proctime AS PROCTIME()
    ) WITH (
        'connector' = 'kafka',
        'topic' = 'joins-input-topic-left',
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
tbl_left = table_env.from_path("tbl_left")
print("\ncreate kafka source table - tbl_left")
tbl_left.print_schema()

table_env.execute_sql(
    f"""
    CREATE TABLE tbl_right (
        kk VARCHAR,
        v VARCHAR,
        proctime AS PROCTIME()
    ) WITH (
        'connector' = 'kafka',
        'topic' = 'joins-input-topic-right',
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
tbl_right = table_env.from_path("tbl_right")
print("\ncreate kafka source table - tbl_right")
tbl_right.print_schema()

## join transformations
inner_joined = table_env.sql_query(
    """
    SELECT COALESCE(l.kk, r.kk) AS kk,
           l.kk AS l_kk, 
           l.v AS l_v, 
           r.kk AS r_kk, 
           r.v AS r_v,
           'inner' AS join_type,
           COALESCE(l.window_start, r.window_start) AS window_start,
           COALESCE(l.window_end, r.window_end) AS window_end
           FROM (
            SELECT * FROM TABLE(TUMBLE(TABLE tbl_left, DESCRIPTOR(proctime), INTERVAL '5' MINUTES))
           ) l
           JOIN (
            SELECT * FROM TABLE(TUMBLE(TABLE tbl_right, DESCRIPTOR(proctime), INTERVAL '5' MINUTES))
           ) r
           ON l.window_start = r.window_start AND l.window_end = r.window_end
    """
)
print("\ninner joined")
inner_joined.print_schema()

## create print sink table
table_env.execute_sql(
    f"""
    CREATE TABLE print (
        kk VARCHAR,
        l_kk VARCHAR,
        l_v VARCHAR,
        r_kk VARCHAR,
        r_v VARCHAR,
        join_type VARCHAR,
        window_start TIMESTAMP(3),
        window_end TIMESTAMP(3)
    ) WITH (
        'connector' = 'print'
    )
    """
)


## create kafka sink table
# table_env.execute_sql(
#     f"""
#     CREATE TABLE output (
#         kk VARCHAR,
#         wc BIGINT,
#         cc BIGINT,
#         w VARCHAR,
#         PRIMARY KEY (kk) NOT ENFORCED
#     ) WITH (
#         'connector' = 'upsert-kafka',
#         'topic' = 'aggregations-output-topic',
#         'properties.bootstrap.servers' = '{BOOTSTRAP_SERVERS}',
#         'key.format' = 'raw',
#         'key.fields-prefix' = 'k',
#         'value.format' = 'json',
#         'value.json.fail-on-missing-field' = 'false',
#         'value.fields-include' = 'EXCEPT_KEY'
#     )
#     """
# )

# ## insert into sink tables
statement_set = table_env.create_statement_set()
statement_set.add_insert("print", inner_joined)
# statement_set.add_insert("output", res)
statement_set.execute().wait()
