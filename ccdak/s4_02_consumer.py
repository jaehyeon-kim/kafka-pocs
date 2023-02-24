import os
import datetime
import logging
from kafka import KafkaConsumer
from kafka.errors import KafkaError

logging.basicConfig(level=logging.INFO)


class Consumer:
    def __init__(self, bootstrap_servers: list, topics: list, group_id: str) -> None:
        self.bootstrap_servers = bootstrap_servers
        self.topics = topics
        self.group_id = group_id
        self.consumer = self.create()

    def create(self):
        return KafkaConsumer(
            *self.topics,
            bootstrap_servers=self.bootstrap_servers,
            auto_offset_reset="earliest",
            enable_auto_commit=True,
            group_id=self.group_id,
            key_deserializer=lambda v: v.decode("utf-8"),
            value_deserializer=lambda v: v.decode("utf-8"),
        )

    def process(self):
        try:
            while True:
                msg = self.consumer.poll(timeout_ms=1000)
                if msg is None:
                    continue
                self.print_info(msg)
        except KafkaError as error:
            logging.error(error)

    def print_info(self, msg: dict):
        for _, v in msg.items():
            for r in v:
                ts = r.timestamp
                dt = datetime.datetime.fromtimestamp(ts / 1000).isoformat()
                logging.info(
                    f"partition - {r.partition}, offset - {r.offset}, ts - {ts}, dt - {dt}, key - {r.key}, value - {r.value}"
                )


if __name__ == "__main__":
    consumer = Consumer(
        bootstrap_servers=os.getenv("BOOTSTRAP_SERVERS", "localhost:9093").split(","),
        topics=os.getenv("TOPIC_NAME", "count-topic").split(","),
        group_id=os.getenv("GROUP_ID", "count-group"),
    )
    consumer.process()
