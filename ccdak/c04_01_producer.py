import os
import datetime
from kafka import KafkaProducer


class Producer:
    def __init__(self, bootstrap_servers: list, topic: str) -> None:
        self.bootstrap_servers = bootstrap_servers
        self.topic = topic
        self.producer = self.create()

    def create(self):
        return KafkaProducer(
            bootstrap_servers=self.bootstrap_servers,
            value_serializer=lambda v: v.encode("utf-8"),
            key_serializer=lambda v: v.encode("utf-8"),
        )

    def send(self, n: int):
        for i in range(n):
            self.producer.send(self.topic, key="count", value=str(i))
        self.producer.flush()


if __name__ == "__main__":
    producer = Producer(
        bootstrap_servers=os.getenv("BOOTSTRAP_SERVERS", "localhost:9093").split(","),
        topic=os.getenv("TOPIC_NAME", "count-topic"),
    ).send(100)
