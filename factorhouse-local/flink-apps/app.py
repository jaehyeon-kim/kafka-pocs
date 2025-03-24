import os
import datetime
import inspect
import dataclasses
import logging
from typing import Tuple

import pyflink.version
from pyflink.datastream import StreamExecutionEnvironment, RuntimeExecutionMode
from pyflink.table import StreamTableEnvironment
from pyflink.common import WatermarkStrategy, Types, Row
from pyflink.common.watermark_strategy import TimestampAssigner, Duration
from pyflink.common.configuration import Configuration
from pyflink.datastream.connectors.kafka import (
    KafkaSink,
    KafkaRecordSerializationSchema,
    DeliveryGuarantee,
)
from pyflink.datastream.formats.json import JsonRowSerializationSchema

RUNTIME_ENV = os.getenv("RUNTIME_ENV", "docker")
BOOTSTRAP_SERVERS = os.getenv(
    "BOOTSTRAP_SERVERS", "kafka-1:19092,kafka-2:19093,kafka-3:19094"
)


def set_pipeline_jars_config(
    runtime_env: str,
    jars: list = [
        "flink-faker-0.5.3.jar",
        "flink-sql-connector-kafka-3.3.0-1.20.jar",
    ],
) -> Configuration:
    ## return pipeline.jars configuration
    src_dir = (
        "/tmp/apps"
        if runtime_env == "docker"
        else os.path.dirname(os.path.realpath(__file__))
    )
    jar_files = [f"file://{os.path.join(src_dir, 'jars', name)}" for name in jars]
    if runtime_env == "docker":
        jar_files = [
            f"file:///opt/flink/opt/flink-python-{pyflink.version.__version__}.jar"
        ] + jar_files
    return Configuration().set_string("pipeline.jars", ";".join(jar_files))


class SourceTimestampAssigner(TimestampAssigner):
    def extract_timestamp(
        self, value: Tuple[int, int, datetime.datetime], record_timestamp: int
    ):
        return int(value[2].strftime("%s")) * 1000


ddl_stmt = inspect.cleandoc(
    """
        CREATE TABLE sensor_source (
            `id`        INT,
            `value`     INT,
            `ts`        TIMESTAMP_LTZ(3)
        )
        WITH (
            'connector' = 'faker',
            'rows-per-second' = '1',
            'fields.id.expression' = '#{number.numberBetween ''0'',''20''}',
            'fields.value.expression' = '#{number.numberBetween ''0'',''100''}',
            'fields.ts.expression' =  '#{date.past ''10'',''5'',''SECONDS''}'
        );
    """
)


@dataclasses.dataclass
class Sensor:
    id: int
    value: int
    ts: str

    @staticmethod
    def to_row(tup: Types.TUPLE):
        return Row(
            id=tup[0], value=tup[1], ts=tup[2].isoformat(timespec="milliseconds")
        )

    @staticmethod
    def get_key_type_info():
        return Types.ROW_NAMED(field_names=["id"], field_types=[Types.INT()])

    @staticmethod
    def get_value_type_info():
        return Types.ROW_NAMED(
            field_names=["id", "value", "ts"],
            field_types=[Types.INT(), Types.INT(), Types.STRING()],
        )


if __name__ == "__main__":
    """
    ## local execution
    BOOTSTRAP_SERVERS=localhost:9092 RUNTIME_ENV=local python app.py

    ## cluster execution
    docker exec jobmanager /opt/flink/bin/flink run \
        --python /tmp/apps/app.py \
        -d
    """

    logger = logging.getLogger(__name__)
    logging.basicConfig(
        format="%(asctime)s - %(levelname)s - %(message)s", datefmt="%Y-%m-%d %H:%M:S"
    )

    env = StreamExecutionEnvironment.get_execution_environment()
    env.set_runtime_mode(RuntimeExecutionMode.STREAMING)
    env.configure(set_pipeline_jars_config(RUNTIME_ENV))

    t_env = StreamTableEnvironment.create(stream_execution_environment=env)
    t_env.get_config().set_local_timezone("Australia/Melbourne")
    t_env.execute_sql(ddl_stmt)

    logger.info("stream environment is set")

    source_stream = t_env.to_append_stream(
        t_env.from_path("sensor_source"),
        Types.TUPLE([Types.INT(), Types.INT(), Types.SQL_TIMESTAMP()]),
    ).assign_timestamps_and_watermarks(
        WatermarkStrategy.for_bounded_out_of_orderness(
            Duration.of_seconds(5)
        ).with_timestamp_assigner(SourceTimestampAssigner())
    )

    logger.info("source stream is set")

    sensor_sink = (
        KafkaSink.builder()
        .set_bootstrap_servers(BOOTSTRAP_SERVERS)
        .set_record_serializer(
            KafkaRecordSerializationSchema.builder()
            .set_topic("sensor")
            .set_key_serialization_schema(
                JsonRowSerializationSchema.builder()
                .with_type_info(Sensor.get_key_type_info())
                .build()
            )
            .set_value_serialization_schema(
                JsonRowSerializationSchema.builder()
                .with_type_info(Sensor.get_value_type_info())
                .build()
            )
            .build()
        )
        .set_delivery_guarantee(DeliveryGuarantee.AT_LEAST_ONCE)
        .build()
    )

    source_stream.map(
        lambda t: Sensor.to_row(t), output_type=Sensor.get_value_type_info()
    ).sink_to(sensor_sink).name("sensor-sink").uid("sensor-sink")

    logger.info("sink to kafka topic - sensor")

    env.execute("Basic kafka sink example")
