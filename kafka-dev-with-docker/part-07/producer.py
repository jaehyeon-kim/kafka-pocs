import os
import datetime
import time
import json
import typing
import logging
import dataclasses
import enum

from faker import Faker
from dataclasses_avroschema import AvroModel
import boto3
import botocore.exceptions
from kafka import KafkaProducer
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
        user_id = str(fake.random_int(1, 100)).zfill(3)
        order_items = [
            OrderItem(fake.random_int(1, 1000), fake.random_int(1, 10))
            for _ in range(fake.random_int(1, 4))
        ]
        return cls(fake.uuid4(), datetime.datetime.utcnow(), user_id, order_items)

    def create(self, num: int):
        return [self.auto() for _ in range(num)]


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
            bootstrap_servers=self.bootstrap_servers,
            key_serializer=lambda v: json.dumps(v, default=self.serialize).encode("utf-8"),
            value_serializer=self.serializer,
        )

    def send(self, orders: typing.List[Order], schema: AvroSchema):
        if not self.check_registry():
            print(f"registry not found, create {self.registry}")
            self.create_registry()

        for order in orders:
            try:
                self.producer.send(
                    self.topic, key={"order_id": order.order_id}, value=(order.asdict(), schema)
                )
            except Exception as e:
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


if __name__ == "__main__":
    producer = Producer(
        bootstrap_servers=os.getenv("BOOTSTRAP_SERVERS", "localhost:29092").split(","),
        topic=os.getenv("TOPIC_NAME", "orders"),
        registry=os.getenv("REGISTRY_NAME", "online-order"),
    )
    max_run = int(os.getenv("MAX_RUN", "-1"))
    logging.info(f"max run - {max_run}")
    current_run = 0
    while True:
        current_run += 1
        logging.info(f"current run - {current_run}")
        if current_run > max_run and max_run >= 0:
            logging.info(f"exceeds max run, finish")
            producer.producer.close()
            break
        orders = Order.auto().create(1)
        schema = AvroSchema(Order.updated_avro_schema(Compatibility.BACKWARD))
        producer.send(Order.auto().create(100), schema)
        time.sleep(1)
