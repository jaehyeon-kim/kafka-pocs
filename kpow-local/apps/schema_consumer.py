import os
import typing

from confluent_kafka import Consumer, KafkaException, TopicPartition
from confluent_kafka.serialization import SerializationContext, MessageField
from confluent_kafka.schema_registry.json_schema import JSONDeserializer

from schema_src import Temperature, schema_str

BOOTSTRAP_SERVERS = os.getenv("BOOTSTRAP_SERVERS", "localhost:9092")
TOPIC_NAME = os.getenv("TOPIC_NAME", "temp-reading")


def set_consumer_configs():
    return {
        "bootstrap.servers": BOOTSTRAP_SERVERS,
        "group.id": f"{TOPIC_NAME}-group",
        "auto.offset.reset": "earliest",
        "enable.auto.commit": False,
    }


def dict_to_temp(d: dict, ctx: SerializationContext):
    return Temperature.from_dict(d)


def assignment_callback(consumer: Consumer, partitions: typing.List[TopicPartition]):
    for p in partitions:
        print(f"Assigned to {p.topic}, partiton {p.partition}")


if __name__ == "__main__":
    json_descrializer = JSONDeserializer(schema_str, from_dict=dict_to_temp)

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
                val = json_descrializer(
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
