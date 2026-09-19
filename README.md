# Kafka POCs

Proof of concept projects for Apache Kafka, each one the code behind a post. Every folder in the table below is a self contained task with its own README.

## Tasks

| Folder | What it demonstrates | Posts |
|---|---|---|
| [glue-schema-registry](./glue-schema-registry) | Producer and consumer Lambda functions on MSK that serialise Avro messages through the AWS Glue Schema Registry. | [Integrate Glue Schema Registry with Your Python Kafka App](https://jaehyeon.me/blog/2023-04-12-integrate-glue-schema-registry/) |
| [integration-athena](./integration-athena) | Querying an MSK topic straight from Athena with the Athena MSK connector, with no pipeline into S3 first. | [Simplify Streaming Ingestion on AWS – Part 2 MSK and Athena](https://jaehyeon.me/blog/2023-03-14-simplify-streaming-ingestion-athena/) |
| [integration-redshift](./integration-redshift) | Ingesting an MSK topic into Redshift Serverless with an external schema and an auto refreshing materialized view. | [Simplify Streaming Ingestion on AWS – Part 1 MSK and Redshift](https://jaehyeon.me/blog/2023-02-08-simplify-streaming-ingestion-redshift/) |
| [kafka-connect-for-aws](./kafka-connect-for-aws) | A Camel DynamoDB sink connector, developed on a local Kafka Connect cluster and then deployed to MSK Connect with Terraform. | [Part 2 Develop Camel DynamoDB Sink Connector](https://jaehyeon.me/blog/2023-06-04-kafka-connect-for-aws-part-2/), [Part 3 Deploy Camel DynamoDB Sink Connector](https://jaehyeon.me/blog/2023-07-03-kafka-connect-for-aws-part-3/) |
| [kafka-dev-on-k8s](./kafka-dev-on-k8s) | A Kafka cluster run on minikube by the Strimzi operator, with Python clients and a Kafka Connect cluster. | [Part 1 Cluster Setup](https://jaehyeon.me/blog/2023-12-21-kafka-development-on-k8s-part-1/), [Part 2 Producer and Consumer](https://jaehyeon.me/blog/2024-01-04-kafka-development-on-k8s-part-2/), [Part 3 Kafka Connect](https://jaehyeon.me/blog/2024-01-11-kafka-development-on-k8s-part-3/) |
| [kafka-dev-with-docker](./kafka-dev-with-docker) | An eleven part Docker Compose series: cluster setup, management app, Kafka Connect, Python clients, the Glue Schema Registry, SSL and SASL, and authorization. | Parts [1](https://jaehyeon.me/blog/2023-05-04-kafka-development-with-docker-part-1/), [2](https://jaehyeon.me/blog/2023-05-18-kafka-development-with-docker-part-2/), [3](https://jaehyeon.me/blog/2023-05-25-kafka-development-with-docker-part-3/), [4](https://jaehyeon.me/blog/2023-06-01-kafka-development-with-docker-part-4/), [5](https://jaehyeon.me/blog/2023-06-08-kafka-development-with-docker-part-5/), [6](https://jaehyeon.me/blog/2023-06-15-kafka-development-with-docker-part-6/), [7](https://jaehyeon.me/blog/2023-06-22-kafka-development-with-docker-part-7/), [8](https://jaehyeon.me/blog/2023-06-29-kafka-development-with-docker-part-8/), [9](https://jaehyeon.me/blog/2023-07-06-kafka-development-with-docker-part-9/), [10](https://jaehyeon.me/blog/2023-07-13-kafka-development-with-docker-part-10/), [11](https://jaehyeon.me/blog/2023-07-20-kafka-development-with-docker-part-11/) |
| [offset-seeking](./offset-seeking) | Seeking Kafka consumer offsets by timestamp where topic partitions are assigned dynamically by subscription. | [How to configure Kafka consumers to seek offsets by timestamp](https://jaehyeon.me/blog/2023-01-10-kafka-consumer-seek-offsets/) |

## Other folders

These five folders are study notes, vendor copies or scratch work. They are not tasks and have no post of their own.

- `ccdak`, notes, scripts and course material kept while studying for the Confluent Certified Developer for Apache Kafka exam.
- `factorhouse-local`, a copy of [factorhouse/kpow-local](https://github.com/factorhouse/kpow-local), the compose files for running Kafka and Kpow locally.
- `misc`, a Kafka UI Glue serde jar and a snippet on testing kafka-python code.
- `msk-lab`, one CloudFormation template from the MSK security workshop.
- `security-course`, notes and configuration from a Kafka security course. Its published form is parts 8 to 11 of Kafka Development with Docker.

## Posts

- [How to configure Kafka consumers to seek offsets by timestamp](https://jaehyeon.me/blog/2023-01-10-kafka-consumer-seek-offsets/)
  - Normally, we consume Kafka messages from the beginning/end of a topic, or the last committed offsets. For backfilling or troubleshooting however, we occasionally need to consume messages from a certain timestamp. The Kafka consumer class of the [kafka-python](https://kafka-python.readthedocs.io/en/master/index.html) package has a method to [seek a particular offset](https://kafka-python.readthedocs.io/en/master/apidoc/KafkaConsumer.html#kafka.KafkaConsumer.seek) for a topic partition. Therefore, if we know which topic partition to choose – such as by [assigning a topic partition](https://kafka-python.readthedocs.io/en/master/apidoc/KafkaConsumer.html#kafka.KafkaConsumer.assign) – we can easily override the fetch offset. When we deploy multiple consumer instances together however, we make them [subscribe to a topic](https://kafka-python.readthedocs.io/en/master/apidoc/KafkaConsumer.html#kafka.KafkaConsumer.subscribe), and topic partitions are dynamically assigned, which means we do not know which topic partition will be assigned to a consumer instance in advance. In this post, we will discuss how to configure the Kafka consumer to seek offsets by timestamp where topic partitions are dynamically assigned by subscription.
- [Simplify Streaming Ingestion on AWS – Part 1 MSK and Redshift](https://jaehyeon.me/blog/2023-02-08-simplify-streaming-ingestion-redshift/)
  - [Apache Kafka](https://kafka.apache.org/) is a popular distributed event store and stream processing platform. Previously loading data from Kafka into Redshift and Athena usually required Kafka connectors (e.g. [Amazon Redshift Sink Connector](https://www.confluent.io/hub/confluentinc/kafka-connect-aws-redshift) and [Amazon S3 Sink Connector](https://www.confluent.io/hub/confluentinc/kafka-connect-s3)). Recently these AWS services provide features to ingest data from Kafka directly, which facilitates a simpler architecture that achieves low-latency and high-speed ingestion of streaming data. In part 1 of the simplify streaming ingestion on AWS series, we discuss how to develop an end-to-end streaming ingestion solution using [EventBridge](https://aws.amazon.com/eventbridge/), [Lambda](https://aws.amazon.com/lambda/), [MSK](https://aws.amazon.com/msk/) and [Redshift Serverless](https://aws.amazon.com/redshift/redshift-serverless/) on AWS.
- [Simplify Streaming Ingestion on AWS – Part 2 MSK and Athena](https://jaehyeon.me/blog/2023-03-14-simplify-streaming-ingestion-athena/)
  - In Part 1, we discussed a streaming ingestion solution using [EventBridge](https://aws.amazon.com/eventbridge/), [Lambda](https://aws.amazon.com/lambda/), [MSK](https://aws.amazon.com/msk/) and [Redshift Serverless](https://aws.amazon.com/redshift/redshift-serverless/). Athena provides the [MSK connector](https://docs.aws.amazon.com/athena/latest/ug/connectors-msk.html) to enable SQL queries on Apache Kafka topics directly and it can also facilitate the extraction of insights without setting up an additional pipeline to store data into S3. In this post, we discuss how to update the streaming ingestion solution so that data in the Kafka topic can be queried by Athena instead of Redshift.
- [Integrate Glue Schema Registry with Your Python Kafka App](https://jaehyeon.me/blog/2023-04-12-integrate-glue-schema-registry/)
  - [Glue Schema Registry](https://docs.aws.amazon.com/glue/latest/dg/schema-registry.html) provides a centralized repository for managing and validating schemas for topic message data. Its features can be utilized by many AWS services when building data streaming applications. In this post, we will discuss how to integrate Python Kafka producer and consumer apps in AWS Lambda with the Glue Schema Registry.
- Kafka Development with Docker
  - Apache Kafka is one of the key technologies for [modern data streaming architectures](https://docs.aws.amazon.com/whitepapers/latest/build-modern-data-streaming-analytics-architectures/build-modern-data-streaming-analytics-architectures.html) on AWS. Developing and testing Kafka-related applications can be easier using [Docker](https://www.docker.com/) and [Docker Compose](https://docs.docker.com/compose/). In this series of posts, I will demonstrate reference implementations of those applications in Dockerized environments.
    - [Part 1 Cluster Setup](https://jaehyeon.me/blog/2023-05-04-kafka-development-with-docker-part-1/)
    - [Part 2 Management App](https://jaehyeon.me/blog/2023-05-18-kafka-development-with-docker-part-2/)
    - [Part 3 Kafka Connect](https://jaehyeon.me/blog/2023-05-25-kafka-development-with-docker-part-3/)
    - [Part 4 Producer and Consumer](https://jaehyeon.me/blog/2023-06-01-kafka-development-with-docker-part-4/)
    - [Part 5 Glue Schema Registry](https://jaehyeon.me/blog/2023-06-08-kafka-development-with-docker-part-5/)
    - [Part 6 Kafka Connect with Glue Schema Registry](https://jaehyeon.me/blog/2023-06-15-kafka-development-with-docker-part-6/)
    - [Part 7 Producer and Consumer with Glue Schema Registry](https://jaehyeon.me/blog/2023-06-22-kafka-development-with-docker-part-7/)
    - [Part 8 SSL Encryption](https://jaehyeon.me/blog/2023-06-29-kafka-development-with-docker-part-8/)
    - [Part 9 SSL Authentication](https://jaehyeon.me/blog/2023-07-06-kafka-development-with-docker-part-9/)
    - [Part 10 SASL Authentication](https://jaehyeon.me/blog/2023-07-13-kafka-development-with-docker-part-10/)
    - [Part 11 Kafka Authorization](https://jaehyeon.me/blog/2023-07-20-kafka-development-with-docker-part-11/)

## License

The code in this repository is released under the MIT License. See [LICENSE](./LICENSE) for the full text.

Some folders hold third-party material that keeps its own terms and is not licensed by this repository. `factorhouse-local` is a copy of [factorhouse/kpow-local](https://github.com/factorhouse/kpow-local) and carries its own Apache-2.0 [LICENSE](./factorhouse-local/LICENSE). `ccdak/course-materials`, `security-course/course-notes` and `msk-lab` are third-party course and workshop material.
