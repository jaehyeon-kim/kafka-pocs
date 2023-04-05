import os
import datetime
import time

from aws_schema_registry.avro import AvroSchema

from src.order import Order, OrderMore, Compatibility
from src.producer import Producer


def lambda_function(event, context):
    producer = Producer(
        bootstrap_servers=os.environ["BOOTSTRAP_SERVERS"].split(","),
        topic=os.environ["TOPIC_NAME"],
        registry=os.environ["REGISTRY_NAME"],
    )
    s = datetime.datetime.now()
    ttl_rec = 0
    while True:
        orders = Order.auto().create(100)
        schema = AvroSchema(Order.updated_avro_schema(Compatibility.BACKWARD))
        producer.send(orders, schema)
        ttl_rec += len(orders)
        print(f"sent {len(orders)} messages")
        elapsed_sec = (datetime.datetime.now() - s).seconds
        if elapsed_sec > int(os.getenv("MAX_RUN_SEC", "60")):
            print(f"{ttl_rec} records are sent in {elapsed_sec} seconds ...")
            break
        time.sleep(1)


if __name__ == "__main__":
    producer = Producer(
        bootstrap_servers=os.environ["BOOTSTRAP_SERVERS"].split(","),
        topic=os.environ["TOPIC_NAME"],
        registry=os.environ["REGISTRY_NAME"],
        is_local=True,
    )
    use_more = os.getenv("USE_MORE") is not None
    if not use_more:
        orders = Order.auto().create(1)
        schema = AvroSchema(Order.updated_avro_schema(Compatibility.BACKWARD))
    else:
        orders = OrderMore.auto().create(1)
        schema = AvroSchema(OrderMore.updated_avro_schema(Compatibility.BACKWARD))
    print(orders)
    producer.send(orders, schema)
