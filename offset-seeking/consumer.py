import os
import datetime
import time
import json
import logging
from kafka import KafkaConsumer, ConsumerRebalanceListener
from kafka.errors import KafkaError
from kafka.structs import TopicPartition

logging.basicConfig(level=logging.INFO)


class Consumer:
    def __init__(
        self, topics: list, group_id: str, bootstrap_servers: list, offset_str: str = None
    ):
        self.topics = topics
        self.group_id = group_id
        self.bootstrap_servers = bootstrap_servers
        self.offset_str = offset_str
        self.consumer = self.create()

    def create(self):
        return KafkaConsumer(
            bootstrap_servers=self.bootstrap_servers,
            auto_offset_reset="earliest",
            enable_auto_commit=True,
            group_id=self.group_id,
            key_deserializer=lambda v: json.loads(v.decode("utf-8")),
            value_deserializer=lambda v: json.loads(v.decode("utf-8")),
        )

    def process(self):
        self.consumer.subscribe(
            self.topics, listener=RebalanceListener(self.consumer, self.offset_str)
        )
        try:
            while True:
                msg = self.consumer.poll(timeout_ms=1000, max_records=1)
                if msg is None:
                    continue
                self.print_info(msg)
                time.sleep(5)
        except KafkaError as error:
            logging.error(error)
        finally:
            self.consumer.close()

    def print_info(self, msg: dict):
        for _, v in msg.items():
            for r in v:
                ts = r.timestamp
                dt = datetime.datetime.fromtimestamp(ts / 1000).isoformat()
                logging.info(
                    f"topic - {r.topic}, partition - {r.partition}, offset - {r.offset}, ts - {ts}, dt - {dt})"
                )


class RebalanceListener(ConsumerRebalanceListener):
    def __init__(self, consumer: KafkaConsumer, offset_str: str = None):
        self.consumer = consumer
        self.offset_str = offset_str

    def on_partitions_revoked(self, revoked):
        pass

    def on_partitions_assigned(self, assigned):
        ts = self.convert_to_ts(self.offset_str)
        logging.info(f"offset_str - {self.offset_str}, timestamp - {ts}")
        if ts is not None:
            for tp in assigned:
                logging.info(f"topic partition - {tp}")
                self.seek_by_timestamp(tp.topic, tp.partition, ts)

    def convert_to_ts(self, offset_str: str):
        try:
            dt = datetime.datetime.fromisoformat(offset_str)
            return int(dt.timestamp() * 1000)
        except Exception:
            return None

    def seek_by_timestamp(self, topic_name: str, partition: int, ts: int):
        tp = TopicPartition(topic_name, partition)
        offset_n_ts = self.consumer.offsets_for_times({tp: ts})
        logging.info(f"offset and ts - {offset_n_ts}")
        if offset_n_ts[tp] is not None:
            offset = offset_n_ts[tp].offset
            try:
                self.consumer.seek(tp, offset)
            except KafkaError:
                logging.error("fails to seek offset")
        else:
            logging.warning("offset is not looked up")


if __name__ == "__main__":
    consumer = Consumer(
        topics=os.getenv("TOPICS", "orders").split(","),
        group_id=os.getenv("GROUP_ID", "orders-group"),
        bootstrap_servers=os.getenv("BOOTSTRAP_SERVERS", "localhost:9093").split(","),
        offset_str=os.getenv("OFFSET_STR", None),
    )
    consumer.process()
