import os
import datetime
import json
import typing

import boto3
import botocore.exceptions
from kafka import KafkaProducer
from aws_schema_registry import SchemaRegistryClient
from aws_schema_registry.avro import AvroSchema
from aws_schema_registry.adapter.kafka import KafkaSerializer
from aws_schema_registry.exception import SchemaRegistryException

from .order import Order


class Producer:
    def __init__(self, bootstrap_servers: list, topic: str, registry: str, is_local: bool = False):
        self.bootstrap_servers = bootstrap_servers
        self.topic = topic
        self.registry = registry
        self.glue_client = boto3.client(
            "glue", region_name=os.getenv("AWS_DEFAULT_REGION", "ap-southeast-2")
        )
        self.is_local = is_local
        self.producer = self.create()

    @property
    def serializer(self):
        client = SchemaRegistryClient(self.glue_client, registry_name=self.registry)
        return KafkaSerializer(client)

    def create(self):
        params = {
            "bootstrap_servers": self.bootstrap_servers,
            "key_serializer": lambda v: json.dumps(v, default=self.serialize).encode("utf-8"),
            "value_serializer": self.serializer,
        }
        if not self.is_local:
            params = {
                **params,
                **{"security_protocol": "SASL_SSL", "sasl_mechanism": "AWS_MSK_IAM"},
            }
        return KafkaProducer(**params)

    def send(self, orders: typing.List[Order], schema: AvroSchema):
        if not self.check_registry():
            print(f"registry not found, create {self.registry}")
            self.create_registry()

        for order in orders:
            data = order.asdict()
            try:
                self.producer.send(
                    self.topic, key={"order_id": data["order_id"]}, value=(data, schema)
                )
            except SchemaRegistryException as e:
                raise RuntimeError("fails to send a message") from e
        self.producer.flush()

    def serialize(self, obj):
        if isinstance(obj, datetime.datetime):
            return obj.isoformat()
        if isinstance(obj, datetime.date):
            return str(obj)
        return obj

    def check_registry(self):
        try:
            self.glue_client.get_registry(RegistryId={"RegistryName": self.registry})
            return True
        except botocore.exceptions.ClientError as e:
            if e.response["Error"]["Code"] == "EntityNotFoundException":
                return False
            else:
                raise e

    def create_registry(self):
        try:
            self.glue_client.create_registry(RegistryName=self.registry)
            return True
        except botocore.exceptions.ClientError as e:
            if e.response["Error"]["Code"] == "AlreadyExistsException":
                return True
            else:
                raise e
