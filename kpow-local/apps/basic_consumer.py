import os
import typing

from confluent_kafka import Consumer, KafkaException, TopicPartition

BOOTSTRAP_SERVERS = os.getenv("BOOTSTRAP_SERVERS", "localhost:9092")
TOPIC_NAME = os.getenv("TOPIC_NAME", "basic-client")


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
                val = event.value().decode("utf8")
                partition = event.partition()
                print(f"Received: {val} from partition {partition}")
                consumer.commit(event)
    except KeyboardInterrupt:
        print("Cancelled by user")
    finally:
        consumer.close()
