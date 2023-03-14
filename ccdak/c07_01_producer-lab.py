import os
from kafka import KafkaProducer

transaction_log = """apples:21
pears:5
beets:7
bananas:8
radishes:34
oranges:7
plantains:27
apples:6
grapes:105
bananas:6
apples:3
radishes:11
pears:9
onions:6
apples:1
plums:8
oranges:1
grapes:206
bananas:3
limes:3""".split(
    "\n"
)


class Producer:
    def __init__(self, bootstrap_servers: list) -> None:
        self.bootstrap_servers = bootstrap_servers
        self.producer = self.create()

    def create(self):
        return KafkaProducer(
            bootstrap_servers=self.bootstrap_servers,
            acks="all",
            value_serializer=lambda v: v.encode("utf-8"),
            key_serializer=lambda v: v.encode("utf-8"),
        )

    def send(self, transaction_log: list):
        for log in transaction_log:
            key, value = tuple(log.split(":"))
            self.producer.send("inventory_purchases", key=key, value=value)
            if key == "apples":
                self.producer.send("apple_purchases", key=key, value=value)
        self.producer.flush()


if __name__ == "__main__":
    producer = Producer(
        bootstrap_servers=os.getenv("BOOTSTRAP_SERVERS", "localhost:9093").split(","),
    ).send(transaction_log)
