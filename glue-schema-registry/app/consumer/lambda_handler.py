import os
import base64
import datetime
import dataclasses
from types import SimpleNamespace

import boto3
from aws_schema_registry import SchemaRegistryClient
from aws_schema_registry.adapter.kafka import KafkaDeserializer

from evt import event

from kafka.consumer.fetcher import ConsumerRecord


@dataclasses.dataclass
class ConsumerRecord:
    topic: str
    partition: int
    offset: int
    timestamp: int
    timestampType: str
    key: str
    value: str
    headers: list

    def decode_key(self):
        pass

    def decode_value(self):
        pass


class Deserializer:
    def __init__(self, registry: str):
        self.registry = registry

    @property
    def glue_client(self):
        return boto3.client("glue", region_name=os.getenv("AWS_DEFAULT_REGION", "ap-southeast-2"))

    @property
    def deserializer(self):
        client = SchemaRegistryClient(self.glue_client, registry_name=self.registry)
        return KafkaDeserializer(client)

    def parse_record(self, record: dict):
        key = record["key"]


coded_string = """Q5YACgA..."""
base64.b64decode(coded_string)

for tp, items in event["records"].items():
    for item in items:
        print(item)

dd = SimpleNamespace(**item)
dd.offset


registry_name = "customer"
glue_client = boto3.client("glue", region_name="ap-southeast-2")
client = SchemaRegistryClient(glue_client, registry_name=registry_name)
deserializer = KafkaDeserializer(client)

base64.b64decode(item["key"])

base64.b64decode(item["value"])

deserializer.deserialize(item["topic"], base64.b64decode(item["value"]))

item


def lambda_function(event, context):
    print(event)
