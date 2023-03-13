import os

from pyflink.table import EnvironmentSettings, TableEnvironment

BOOTSTRAP_SERVERS = os.getenv("BOOTSTRAP_SERVERS", "localhost:9093")
# https://nightlies.apache.org/flink/flink-docs-release-1.16/docs/connectors/table/kafka/
FLINK_SQL_CONNECTOR_KAFKA = "flink-sql-connector-kafka-1.16.0.jar"

env_settings = EnvironmentSettings.in_streaming_mode()
table_env = TableEnvironment.create(env_settings)
# https://nightlies.apache.org/flink/flink-docs-release-1.16/docs/dev/python/dependency_management/
kafka_jar = os.path.join(os.path.abspath(os.path.dirname(__file__)), FLINK_SQL_CONNECTOR_KAFKA)
table_env.get_config().set("pipeline.jars", f"file://{kafka_jar}")

## create kafka source table
# table_env.execute_sql(
#     f"""
#     CREATE TABLE input (
#         mykey VARCHAR,
#         myvalue VARCHAR
#     ) WITH (
#         'connector' = 'kafka',
#         'topic' = 'streams-input-topic',
#         'properties.bootstrap.servers' = '{BOOTSTRAP_SERVERS}',
#         'properties.group.id' = 'source-demo',
#         'scan.startup.mode' = 'earliest-offset',
#         'key.format' = 'json',
#         'key.json.ignore-parse-errors' = 'true',
#         'key.fields' = 'mykey',
#         'value.format' = 'json',
#         'value.json.fail-on-missing-field' = 'false',
#         'value.fields-include' = 'EXCEPT_KEY'
#     )
#     """
# )
table_env.execute_sql(
    f"""
    CREATE TABLE input (
        k VARCHAR,
        v VARCHAR
    ) WITH (
        'connector' = 'kafka',
        'topic' = 'streams-input-topic',
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
tbl.print_schema()

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
# table_env.execute_sql(
#     f"""
#     CREATE TABLE output (
#         mykey VARCHAR,
#         myvalue VARCHAR
#     ) WITH (
#         'connector' = 'kafka',
#         'topic' = 'streams-output-topic',
#         'properties.bootstrap.servers' = '{BOOTSTRAP_SERVERS}',
#         'key.format' = 'json',
#         'key.json.ignore-parse-errors' = 'true',
#         'key.fields' = 'mykey',
#         'value.format' = 'json',
#         'value.json.fail-on-missing-field' = 'false',
#         'value.fields-include' = 'EXCEPT_KEY'
#     )
#     """
# )
table_env.execute_sql(
    f"""
    CREATE TABLE output (
        k VARCHAR,
        v VARCHAR
    ) WITH (
        'connector' = 'kafka',
        'topic' = 'streams-output-topic',
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
statement_set.add_insert("print", tbl)
statement_set.add_insert("output", tbl)
statement_set.execute().wait()
