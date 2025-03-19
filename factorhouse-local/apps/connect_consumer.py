import os
import typing
import dataclasses
import decimal

from confluent_kafka import Consumer, KafkaException, TopicPartition
from confluent_kafka.serialization import SerializationContext, MessageField
from confluent_kafka.schema_registry import SchemaRegistryClient
from confluent_kafka.schema_registry.avro import AvroDeserializer

BOOTSTRAP_SERVERS = os.getenv("BOOTSTRAP_SERVERS", "localhost:9092")
SCHEMA_REGISTRY_URL = os.getenv("SCHEMA_REGISTRY_URL", "http://localhost:8081")
TOPIC_NAME = os.getenv("TOPIC_NAME", "purchases")


@dataclasses.dataclass
class Purchase:
    id: int
    item_type: str
    quantity: int
    price_per_unit: decimal.Decimal

    @staticmethod
    def from_dict(d: dict, ctx: SerializationContext):
        return Purchase(**d)


def set_consumer_configs():
    return {
        "bootstrap.servers": BOOTSTRAP_SERVERS,
        "group.id": f"{TOPIC_NAME}-group",
        "auto.offset.reset": "earliest",
        "enable.auto.commit": False,
    }


def assignment_callback(consumer: Consumer, partitions: typing.List[TopicPartition]):
    for p in partitions:
        print(f"Assigned to {p.topic}, partiton {p.partition}")


if __name__ == "__main__":
    schema_registry_conf = {
        "url": SCHEMA_REGISTRY_URL,
        "basic.auth.user.info": "admin:admin",
    }
    schema_registry_client = SchemaRegistryClient(schema_registry_conf)
    avro_descrializer = AvroDeserializer(
        schema_registry_client=schema_registry_client,
        from_dict=Purchase.from_dict,
    )

    conf = set_consumer_configs()
    consumer = Consumer(conf)
    consumer.subscribe([TOPIC_NAME], on_assign=assignment_callback)

    try:
        while True:
            event = consumer.poll(1.0)
            if event is None:
                continue
            if event.error():
                raise KafkaException(event.error())
            else:
                val = avro_descrializer(
                    event.value(), SerializationContext(TOPIC_NAME, MessageField.VALUE)
                )
                partition = event.partition()
                if val is not None:
                    print(f"Received: {val} from partition {partition}")
                consumer.commit()
    except KeyboardInterrupt:
        print("Cancelled by user")
    finally:
        consumer.close()
