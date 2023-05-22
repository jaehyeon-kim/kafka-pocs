import os
import time
import logging

from kafka import KafkaConsumer
from kafka.errors import KafkaError
import boto3
from aws_schema_registry import SchemaRegistryClient, DataAndSchema
from aws_schema_registry.adapter.kafka import KafkaDeserializer

logging.basicConfig(level=logging.INFO)


class Consumer:
    def __init__(self, bootstrap_servers: list, topics: list, group_id: str, registry: str) -> None:
        self.bootstrap_servers = bootstrap_servers
        self.topics = topics
        self.group_id = group_id
        self.registry = registry
        self.glue_client = boto3.client(
            "glue", region_name=os.getenv("AWS_DEFAULT_REGION", "ap-southeast-2")
        )
        self.consumer = self.create()

    @property
    def deserializer(self):
        client = SchemaRegistryClient(self.glue_client, registry_name=self.registry)
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
                value: DataAndSchema = r.value
                logging.info(
                    f"key={r.key}, value={value.data}, topic={t.topic}, partition={t.partition}, offset={r.offset}, ts={r.timestamp}"
                )


if __name__ == "__main__":
    consumer = Consumer(
        bootstrap_servers=os.getenv("BOOTSTRAP_SERVERS", "localhost:29092").split(","),
        topics=os.getenv("TOPIC_NAME", "orders").split(","),
        group_id=os.getenv("GROUP_ID", "orders-group"),
        registry=os.getenv("REGISTRY_NAME", "online-order"),
    )
    consumer.process()
