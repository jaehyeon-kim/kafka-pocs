import os
import datetime
import inspect
from typing import Tuple

from pyflink.datastream import StreamExecutionEnvironment, RuntimeExecutionMode
from pyflink.table import StreamTableEnvironment
from pyflink.common import WatermarkStrategy
from pyflink.common.typeinfo import Types
from pyflink.common.watermark_strategy import TimestampAssigner, Duration

RUNTIME_ENV = os.getenv("RUNTIME_ENV", "docker")


class SourceTimestampAssigner(TimestampAssigner):
    def extract_timestamp(
        self, value: Tuple[int, int, datetime.datetime], record_timestamp: int
    ):
        return int(value[2].strftime("%s")) * 1000


ddl_stmt = inspect.cleandoc(
    """
        CREATE TABLE sensor_source (
            `id`        INT,
            `rn`        INT,
            `log_time`  TIMESTAMP_LTZ(3)
        )
        WITH (
            'connector' = 'faker',
            'rows-per-second' = '1',
            'fields.id.expression' = '#{number.numberBetween ''0'',''20''}',
            'fields.rn.expression' = '#{number.numberBetween ''0'',''100''}',
            'fields.log_time.expression' =  '#{date.past ''10'',''5'',''SECONDS''}'
        );
    """
)

if __name__ == "__main__":
    """
    ## local execution
    RUNTIME_ENV=local python faker.py

    ## cluster execution
    docker exec jobmanager /opt/flink/bin/flink run \
        --python /tmp/apps/faker.py \
        -d
    """

    env = StreamExecutionEnvironment.get_execution_environment()
    env.set_runtime_mode(RuntimeExecutionMode.STREAMING)

    if RUNTIME_ENV == "local":
        SRC_DIR = os.path.dirname(os.path.realpath(__file__))
        JAR_FILES = tuple(
            [
                f"file://{os.path.join(SRC_DIR, 'jars', name)}"
                for name in [
                    "flink-faker-0.5.3.jar",
                    "flink-sql-connector-kafka-3.3.0-1.20.jar",
                ]
            ]
        )
        env.add_jars(*JAR_FILES)

    t_env = StreamTableEnvironment.create(stream_execution_environment=env)
    t_env.get_config().set_local_timezone("Australia/Melbourne")
    t_env.execute_sql(ddl_stmt)

    source_stream = t_env.to_append_stream(
        t_env.from_path("sensor_source"),
        Types.TUPLE([Types.INT(), Types.INT(), Types.SQL_TIMESTAMP()]),
    ).assign_timestamps_and_watermarks(
        WatermarkStrategy.for_bounded_out_of_orderness(
            Duration.of_seconds(5)
        ).with_timestamp_assigner(SourceTimestampAssigner())
    )

    source_stream.print()

    env.execute("Basic faker example")
