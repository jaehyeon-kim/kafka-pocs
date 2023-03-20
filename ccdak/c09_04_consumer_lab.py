import os
import datetime
import time
import logging
import boto3
from kafka import KafkaConsumer
from kafka.errors import KafkaError
from aws_schema_registry import SchemaRegistryClient
from aws_schema_registry.adapter.kafka import KafkaDeserializer

logging.basicConfig(level=logging.INFO)


class Consumer:
    def __init__(
        self, bootstrap_servers: list, topics: list, group_id: str, registry_name: str = "ccdak"
    ):
        self.bootstrap_servers = bootstrap_servers
        self.topics = topics
        self.group_id = group_id
        self.registry_name = registry_name
        self.glue_client = boto3.client("glue", region_name="ap-southeast-2")
        self.consumer = self.create()

    @property
    def deserializer(self):
        client = SchemaRegistryClient(self.glue_client, registry_name=self.registry_name)
        return KafkaDeserializer(client)

    def create(self):
        return KafkaConsumer(
            *self.topics,
            bootstrap_servers=self.bootstrap_servers,
            auto_offset_reset="earliest",
            enable_auto_commit=True,
            group_id=self.group_id,
            key_deserializer=lambda v: v.decode("utf-8"),
            value_deserializer=self.deserializer,
        )

    def process(self):
        try:
            while True:
                msg = self.consumer.poll(timeout_ms=1000)
                if msg is None:
                    continue
                self.print_info(msg)
                time.sleep(1)
        except KafkaError as error:
            logging.error(error)

    def print_info(self, msg: dict):
        for t, v in msg.items():
            for r in v:
                ts = r.timestamp
                dt = datetime.datetime.fromtimestamp(ts / 1000).isoformat()
                logging.info(
                    f"key={r.key}, value={r.value}, topic={t.topic}, partition={t.partition}, offset={r.offset}, ts={ts}, dt={dt}"
                )


if __name__ == "__main__":
    consumer = Consumer(
        bootstrap_servers=os.getenv("BOOTSTRAP_SERVERS", "localhost:9093").split(","),
        topics=os.getenv("TOPIC_NAME", "purchases").split(","),
        group_id=os.getenv("GROUP_ID", "purchases-group"),
        registry_name="ccdak",
    )
    consumer.process()
