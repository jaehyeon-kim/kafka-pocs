import os
import datetime
import string
import json
import time
import typing
import dataclasses
import enum
import logging

import boto3
import botocore.exceptions
from kafka import KafkaProducer
from faker import Faker
from dataclasses_avroschema import AvroModel
from aws_schema_registry import SchemaRegistryClient
from aws_schema_registry.avro import AvroSchema
from aws_schema_registry.adapter.kafka import KafkaSerializer

logging.basicConfig(level=logging.INFO)


class Compatibility(enum.Enum):
    NONE = "NONE"
    DISABLED = "DISABLED"
    BACKWARD = "BACKWARD"
    BACKWARD_ALL = "BACKWARD_ALL"
    FORWARD = "FORWARD"
    FORWARD_ALL = "FORWARD_ALL"
    FULL = "FULL"
    FULL_ALL = "FULL_ALL"


class InjectCompatMixin:
    @classmethod
    def updated_avro_schema_to_python(cls, compat: Compatibility = Compatibility.BACKWARD):
        schema = cls.avro_schema_to_python()
        schema["compatibility"] = compat.value
        return schema

    @classmethod
    def updated_avro_schema(cls, compat: Compatibility = Compatibility.BACKWARD):
        schema = cls.updated_avro_schema_to_python(compat)
        return json.dumps(schema)


@dataclasses.dataclass
class OrderItem(AvroModel):
    product_id: int
    quantity: int


@dataclasses.dataclass
class Order(AvroModel, InjectCompatMixin):
    "Online fake order item"
    order_id: str
    ordered_at: datetime.datetime
    user_id: str
    order_items: typing.List[OrderItem]

    class Meta:
        namespace = "Order V1"

    def asdict(self):
        return dataclasses.asdict(self)

    @classmethod
    def auto(cls, fake: Faker = Faker()):
        rand_int = fake.random_int(1, 1000)
        user_id = "".join(
            [string.ascii_lowercase[int(s)] if s.isdigit() else s for s in hex(rand_int)]
        )[::-1]
        order_items = [
            OrderItem(fake.random_int(1, 9999), fake.random_int(1, 10))
            for _ in range(fake.random_int(1, 4))
        ]
        return cls(fake.uuid4(), datetime.datetime.utcnow(), user_id, order_items)

    def create(self, num: int):
        return [Order.auto() for _ in range(num)]


class Producer:
    def __init__(self, bootstrap_servers: list, topic: str, registry: str):
        self.bootstrap_servers = bootstrap_servers
        self.topic = topic
        self.registry = registry
        self.glue_client = boto3.client(
            "glue", region_name=os.getenv("AWS_DEFAULT_REGION", "ap-southeast-2")
        )
        self.producer = self.create()

    @property
    def serializer(self):
        client = SchemaRegistryClient(self.glue_client, registry_name=self.registry)
        return KafkaSerializer(client)

    def create(self):
        return KafkaProducer(
            security_protocol="SASL_SSL",
            sasl_mechanism="AWS_MSK_IAM",
            bootstrap_servers=self.bootstrap_servers,
            key_serializer=lambda v: json.dumps(v, default=self.serialize).encode("utf-8"),
            value_serializer=self.serializer,
        )

    def send(self, orders: typing.List[Order], schema: AvroSchema):
        if not self.check_registry():
            logging.info(f"registry not found, create {self.registry}")
            self.create_registry()

        for order in orders:
            data = order.asdict()
            self.producer.send(self.topic, key={"order_id": data["order_id"]}, value=(data, schema))
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


def lambda_function(event, context):
    producer = Producer(
        bootstrap_servers=os.environ["BOOTSTRAP_SERVERS"].split(","),
        topic=os.environ["TOPIC_NAME"],
        registry=os.environ["REGISTRY_NAME"],
    )
    s = datetime.datetime.now()
    ttl_rec = 0
    while True:
        orders = Order.auto().create(100)
        schema = AvroSchema(Order.updated_avro_schema(Compatibility.BACKWARD))
        producer.send(orders, schema)
        ttl_rec += len(orders)
        logging.info(f"sent {len(orders)} messages")
        elapsed_sec = (datetime.datetime.now() - s).seconds
        if elapsed_sec > int(os.getenv("MAX_RUN_SEC", "60")):
            logging.info(f"{ttl_rec} records are sent in {elapsed_sec} seconds ...")
            break
        time.sleep(1)


if __name__ == "__main__":
    lambda_function({}, {})
