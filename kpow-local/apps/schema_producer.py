import os
import time
import dataclasses

from confluent_kafka import Producer
from confluent_kafka.serialization import SerializationContext, MessageField
from confluent_kafka.schema_registry import SchemaRegistryClient
from confluent_kafka.schema_registry.json_schema import JSONSerializer
from confluent_kafka.admin import AdminClient

from admin_src import topic_exists, create_topic
from schema_src import Temperature, schema_str

BOOTSTRAP_SERVERS = os.getenv("BOOTSTRAP_SERVERS", "localhost:9092")
SCHEMA_REGISTRY_URL = os.getenv("SCHEMA_REGISTRY_URL", "http://localhost:8081")
TOPIC_NAME = os.getenv("TOPIC_NAME", "temp-reading")


def temp_to_dict(temp: Temperature, ctx: SerializationContext):
    return dataclasses.asdict(temp)


def delivery_report(err, event):
    if err is not None:
        print(f"Delivery failed on reading for {event.key().decode('utf8')}: {err}")
    else:
        print(
            f"Temp reading for {event.key().decode('utf8')} produced to {event.topic()}"
        )


if __name__ == "__main__":
    ## admin
    conf = {"bootstrap.servers": BOOTSTRAP_SERVERS}
    admin_client = AdminClient(conf)
    if not topic_exists(admin_client, TOPIC_NAME):
        create_topic(admin_client, TOPIC_NAME)
    ## producer
    schema_registry_conf = {
        "url": SCHEMA_REGISTRY_URL,
        "basic.auth.user.info": "admin:admin",
    }
    schema_registry_client = SchemaRegistryClient(schema_registry_conf)
    json_serializer = JSONSerializer(schema_str, schema_registry_client, temp_to_dict)

    temp_data = [
        Temperature("London", 12, "C", round(time.time() * 1000)),
        Temperature("Chicago", 63, "F", round(time.time() * 1000)),
        Temperature("Berlin", 14, "C", round(time.time() * 1000)),
        Temperature("Madrid", 18, "C", round(time.time() * 1000)),
        Temperature("Phoenix", 78, "F", round(time.time() * 1000)),
    ]

    produer = Producer(conf)
    for temp in temp_data:
        produer.produce(
            topic=TOPIC_NAME,
            key=str(temp.city),
            value=json_serializer(
                temp, SerializationContext(TOPIC_NAME, MessageField.VALUE)
            ),
            on_delivery=delivery_report,
        )
    produer.flush()
