import re
import datetime
import time
import json
from kafka import KafkaProducer
from faker import Faker


class Order:
    def __init__(self, fake: Faker = None):
        self.fake = fake or Faker()

    def order(self):
        return {"order_id": self.fake.uuid4(), "ordered_at": self.fake.date_time_this_decade()}

    def items(self):
        return [
            {"product_id": self.fake.uuid4(), "quantity": self.fake.random_int(1, 10)}
            for _ in range(self.fake.random_int(1, 4))
        ]

    def customer(self):
        name = self.fake.name()
        email = f'{re.sub(" ", "_", name.lower())}@{re.sub(r"^.*?@", "", self.fake.email())}'
        return {
            "user_id": self.fake.uuid4(),
            "name": name,
            "dob": self.fake.date_of_birth(),
            "address": self.fake.address(),
            "phone": self.fake.phone_number(),
            "email": email,
        }

    def create(self, num: int):
        return [
            {**self.order(), **{"items": self.items(), "customer": self.customer()}}
            for _ in range(num)
        ]


class Producer:
    def __init__(self, bootstrap_servers: list, topic: str):
        self.bootstrap_servers = bootstrap_servers
        self.topic = topic
        self.producer = self.create()

    def create(self):
        return KafkaProducer(
            bootstrap_servers=self.bootstrap_servers,
            value_serializer=lambda v: json.dumps(v, default=self.serialize).encode("utf-8"),
            key_serializer=lambda v: json.dumps(v, default=self.serialize).encode("utf-8"),
        )

    def send(self, orders: list):
        for order in orders:
            self.producer.send(self.topic, key={"order_id": order["order_id"]}, value=order)
        self.producer.flush()

    def serialize(self, obj):
        if isinstance(obj, datetime.datetime):
            return obj.isoformat()
        if isinstance(obj, datetime.date):
            return str(obj)
        return obj


if __name__ == "__main__":
    fake = Faker()
    # Faker.seed(1237)
    producer = Producer(bootstrap_servers=["localhost:9093"], topic="orders")

    while True:
        orders = Order(fake).create(10)
        producer.send(orders)
        print("messages sent...")
        time.sleep(5)
