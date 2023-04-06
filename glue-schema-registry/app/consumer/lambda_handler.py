import os
import json
import base64
import datetime

import boto3
from aws_schema_registry import SchemaRegistryClient
from aws_schema_registry.adapter.kafka import Deserializer, KafkaDeserializer


class LambdaDeserializer(Deserializer):
    def __init__(self, registry: str):
        self.registry = registry

    @property
    def deserializer(self):
        glue_client = boto3.client(
            "glue", region_name=os.getenv("AWS_DEFAULT_REGION", "ap-southeast-2")
        )
        client = SchemaRegistryClient(glue_client, registry_name=self.registry)
        return KafkaDeserializer(client)

    def deserialize(self, topic: str, bytes_: bytes):
        return self.deserializer.deserialize(topic, bytes_)


class ConsumerRecord:
    def __init__(self, record: dict):
        self.topic = record["topic"]
        self.partition = record["partition"]
        self.offset = record["offset"]
        self.timestamp = record["timestamp"]
        self.timestamp_type = record["timestampType"]
        self.key = record["key"]
        self.value = record["value"]
        self.headers = record["headers"]

    def parse_key(self):
        return base64.b64decode(self.key).decode()

    def parse_value(self, deserializer: LambdaDeserializer):
        parsed = deserializer.deserialize(self.topic, base64.b64decode(self.value))
        return parsed.data

    def format_timestamp(self, to_str: bool = True):
        ts = datetime.datetime.fromtimestamp(self.timestamp / 1000)
        if to_str:
            return ts.isoformat()
        return ts

    def parse_record(
        self, deserializer: LambdaDeserializer, to_str: bool = True, to_json: bool = True
    ):
        rec = {
            **self.__dict__,
            **{
                "key": self.parse_key(),
                "value": self.parse_value(deserializer),
                "timestamp": self.format_timestamp(to_str),
            },
        }
        if to_json:
            return json.dumps(rec, default=self.serialize)
        return rec

    def serialize(self, obj):
        if isinstance(obj, datetime.datetime):
            return obj.isoformat()
        if isinstance(obj, datetime.date):
            return str(obj)
        return obj


def lambda_function(event, context):
    deserializer = LambdaDeserializer(os.getenv("REGISTRY_NAME", "customer"))
    for _, records in event["records"].items():
        for record in records:
            cr = ConsumerRecord(record)
            print(cr.parse_record(deserializer))
