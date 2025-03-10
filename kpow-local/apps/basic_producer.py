import os

from confluent_kafka import Producer
from confluent_kafka.admin import AdminClient

from basic_admin import topic_exists, create_topic, get_max_size, set_max_size

BOOTSTRAP_SERVERS = os.getenv("BOOTSTRAP_SERVERS", "localhost:9092")
TOPIC_NAME = os.getenv("TOPIC_NAME", "basic-client")
MAX_MSG_K = 50


def callback(err, event):
    if err:
        print(f"Produce to topic {event.topic()} failed for event: {event.key()}")
    else:
        print(event)
        val = event.value().decode("utf8")
        print(f"{val} sent to partition {event.partition()}.")


def say_hello(producer: Producer, topic_name: str, key: str):
    value = f"Hello {key}!"
    producer.produce(topic_name, value, key, on_delivery=callback)


if __name__ == "__main__":
    ## admin
    conf = {"bootstrap.servers": BOOTSTRAP_SERVERS}
    admin_client = AdminClient(conf)
    if not topic_exists(admin_client, TOPIC_NAME):
        create_topic(admin_client, TOPIC_NAME)
    current_max = get_max_size(admin_client, TOPIC_NAME)
    if current_max != str(MAX_MSG_K * 1024):
        print(f"Topic, {TOPIC_NAME} max.message.bytes is {current_max}.")
        set_max_size(admin_client, TOPIC_NAME, MAX_MSG_K)
    ## producer
    producer = Producer(conf)
    keys = ["Amy", "Brenda", "Cindy", "Derrick", "Elaine", "Fred"]
    for key in keys:
        say_hello(producer, TOPIC_NAME, key)
    producer.flush()
