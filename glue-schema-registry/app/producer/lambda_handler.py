import os
import datetime
import string
import json
import time
from kafka import KafkaProducer
from faker import Faker


class Order:
    def __init__(self, fake: Faker = None):
        self.fake = fake or Faker()

    def order(self):
        rand_int = self.fake.random_int(1, 1000)
        user_id = "".join(
            [string.ascii_lowercase[int(s)] if s.isdigit() else s for s in hex(rand_int)]
        )[::-1]
        return {
            "order_id": self.fake.uuid4(),
            "ordered_at": datetime.datetime.utcnow(),
            "user_id": user_id,
        }

    def items(self):
        return [
            {
                "product_id": self.fake.random_int(1, 9999),
                "quantity": self.fake.random_int(1, 10),
            }
            for _ in range(self.fake.random_int(1, 4))
        ]

    def create(self, num: int):
        return [{**self.order(), **{"items": self.items()}} for _ in range(num)]


class Producer:
    def __init__(self, bootstrap_servers: list, topic: str):
        self.bootstrap_servers = bootstrap_servers
        self.topic = topic
        self.producer = self.create()

    def create(self):
        return KafkaProducer(
            security_protocol="SASL_SSL",
            sasl_mechanism="AWS_MSK_IAM",
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


def lambda_function(event, context):
    if os.getenv("BOOTSTRAP_SERVERS", "") == "":
        return
    fake = Faker()
    producer = Producer(
        bootstrap_servers=os.getenv("BOOTSTRAP_SERVERS").split(","), topic=os.getenv("TOPIC_NAME")
    )
    s = datetime.datetime.now()
    ttl_rec = 0
    while True:
        orders = Order(fake).create(100)
        producer.send(orders)
        ttl_rec += len(orders)
        print(f"sent {len(orders)} messages")
        elapsed_sec = (datetime.datetime.now() - s).seconds
        if elapsed_sec > int(os.getenv("MAX_RUN_SEC", "60")):
            print(f"{ttl_rec} records are sent in {elapsed_sec} seconds ...")
            break
        time.sleep(1)
