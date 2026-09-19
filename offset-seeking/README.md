# Consumer Offset Seeking Demo

A Kafka consumer that overrides its fetch offsets by timestamp, so that a consumer group can be replayed from a point in time even though topic partitions are assigned dynamically by subscription.

## Stack

- ZooKeeper `bitnami/zookeeper:3.7.0` and a single Kafka broker `bitnami/kafka:2.8.1`, defined in `compose-kafka.yml`. The broker has an internal listener on `kafka:9092` and an external listener on `localhost:9093`. The data directories are mapped to `./.bitnami` so topics and messages survive a restart.
- Kafka UI `provectuslabs/kafka-ui:master` on `http://localhost:8080`, in the same compose file.
- `producer.py`, a Python producer that builds fake order records with Faker and sends them to the `orders` topic. It runs on the host and uses the external listener.
- `consumer.py`, a Python consumer that registers a `ConsumerRebalanceListener`. On partition assignment the listener calls `offsets_for_times` and seeks each partition to the offset for `OFFSET_STR`.
- `compose-consumer.yml` runs the consumer in `bitnami/python:3.9`. It sets `TOPICS=orders`, `GROUP_ID=orders-group`, `BOOTSTRAP_SERVERS=kafka:9092`, `OFFSET_STR=2023-01-06T19:00:00` and `TZ=Australia/Sydney`.
- Python packages are pinned by name only in `requirements.txt`: `Faker` and `kafka-python`. `requirements-dev.txt` adds `black`, `pytest` and `pytest-cov`.

## How to run

Start the Kafka cluster and the Kafka UI.

```bash
docker-compose -f compose-kafka.yml up -d
```

Install the Python packages and send order messages from the host.

```bash
pip install -r requirements.txt
python producer.py
```

Start two consumer instances. Change `OFFSET_STR` in `compose-consumer.yml` first if you want a different starting timestamp.

```bash
docker-compose -f compose-consumer.yml up -d --scale consumer=2
```

Stop everything. The consumer compose file joins the `kafka-network` network created by the Kafka compose file, so bring the consumers down first.

```bash
docker-compose -f compose-consumer.yml down
docker-compose -f compose-kafka.yml down
```

Everything runs locally in Docker. No AWS resources are created and nothing is charged.

## Posts

- [How to configure Kafka consumers to seek offsets by timestamp](https://jaehyeon.me/blog/2023-01-10-kafka-consumer-seek-offsets/)

## Repository

[Back to the repository root](../README.md)

## Bitnami images

Bitnami's public Docker images have been moved to the [**Bitnami Legacy**](https://hub.docker.com/u/bitnamilegacy) repository. To ensure continued access and compatibility, please update your Docker image references accordingly.

For example:

- `bitnami/kafka:2.8.1` → `bitnamilegacy/kafka:2.8.1`
- `bitnami/zookeeper:3.7.0` → `bitnamilegacy/zookeeper:3.7.0`
- `bitnami/python:3.9` → `bitnamilegacy/python:3.9`
