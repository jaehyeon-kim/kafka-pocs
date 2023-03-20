import os
import dataclasses
from typing import List
import boto3
import botocore.exceptions
from aws_schema_registry import SchemaRegistryClient
from aws_schema_registry.avro import AvroSchema
from aws_schema_registry.adapter.kafka import KafkaSerializer
from kafka import KafkaProducer


@dataclasses.dataclass
class Purchase:
    id: int
    name: str
    quantity: int

    def asdict(self):
        return dataclasses.asdict(self)


class Producer:
    def __init__(self, bootstrap_servers: list, topic_name: str, registry_name: str = "ccdak"):
        self.bootstrap_servers = bootstrap_servers
        self.topic_name = topic_name
        self.registry_name = registry_name
        self.glue_client = boto3.client("glue", region_name="ap-southeast-2")
        self.producer = self.create()

    @property
    def serializer(self):
        client = SchemaRegistryClient(self.glue_client, registry_name=self.registry_name)
        return KafkaSerializer(client)

    def create(self):
        return KafkaProducer(
            bootstrap_servers=self.bootstrap_servers,
            key_serializer=lambda v: v.encode("utf-8"),
            value_serializer=self.serializer,
        )

    def send(self, purchases: List[Purchase], schema: AvroSchema):
        if not self.check_registry():
            self.create_registry()

        for purchase in purchases:
            data = purchase.asdict()
            self.producer.send(self.topic_name, key=str(data["id"]), value=(data, schema))
        self.producer.flush()

    def check_registry(self):
        try:
            self.glue_client.get_registry(RegistryId={"RegistryName": self.registry_name})
            return True
        except botocore.exceptions.ClientError as e:
            if e.response["Error"]["Code"] == "EntityNotFoundException":
                return False
            else:
                raise e

    def create_registry(self):
        try:
            self.glue_client.create_registry(RegistryName=self.registry_name)
            return True
        except botocore.exceptions.ClientError as e:
            if e.response["Error"]["Code"] == "AlreadyExistsException":
                return True
            else:
                raise e


if __name__ == "__main__":
    purchases = [Purchase(1, "apples", 12), Purchase(2, "grapes", 23)]
    schema = AvroSchema(
        {
            "namespace": "com.linuxacademy.ccdak.schemaregistry",
            "type": "record",
            "name": "Purchase",
            "fields": [
                {"name": "id", "type": "int"},
                {"name": "name", "type": "string"},
                {"name": "quantity", "type": "int"},
            ],
        }
    )
    producer = Producer(
        bootstrap_servers=os.getenv("BOOTSTRAP_SERVERS", "localhost:9093").split(","),
        topic_name="purchases",
        registry_name="ccdak",
    ).send(purchases, schema)
