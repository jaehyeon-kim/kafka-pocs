# Kafka POCs

## Kafka POC projects

- [How to configure Kafka consumers to seek offsets by timestamp](https://jaehyeon.me/blog/2023-01-10-kafka-consumer-seek-offsets/)
  - Normally, we consume Kafka messages from the beginning/end of a topic, or the last committed offsets. For backfilling or troubleshooting however, we occasionally need to consume messages from a certain timestamp. The Kafka consumer class of the [kafka-python](https://kafka-python.readthedocs.io/en/master/index.html) package has a method to [seek a particular offset](https://kafka-python.readthedocs.io/en/master/apidoc/KafkaConsumer.html#kafka.KafkaConsumer.seek) for a topic partition. Therefore, if we know which topic partition to choose – such as by [assigning a topic partition](https://kafka-python.readthedocs.io/en/master/apidoc/KafkaConsumer.html#kafka.KafkaConsumer.assign) – we can easily override the fetch offset. When we deploy multiple consumer instances together however, we make them [subscribe to a topic](https://kafka-python.readthedocs.io/en/master/apidoc/KafkaConsumer.html#kafka.KafkaConsumer.subscribe), and topic partitions are dynamically assigned, which means we do not know which topic partition will be assigned to a consumer instance in advance. In this post, we will discuss how to configure the Kafka consumer to seek offsets by timestamp where topic partitions are dynamically assigned by subscription.
- [Simplify Streaming Ingestion on AWS – Part 1 MSK and Redshift](https://jaehyeon.me/blog/2023-02-08-simplify-streaming-ingestion-redshift/)
  - [Apache Kafka](https://kafka.apache.org/) is a popular distributed event store and stream processing platform. Previously loading data from Kafka into Redshift and Athena usually required Kafka connectors (e.g. [Amazon Redshift Sink Connector](https://www.confluent.io/hub/confluentinc/kafka-connect-aws-redshift) and [Amazon S3 Sink Connector](https://www.confluent.io/hub/confluentinc/kafka-connect-s3)). Recently these AWS services provide features to ingest data from Kafka directly, which facilitates a simpler architecture that achieves low-latency and high-speed ingestion of streaming data. In part 1 of the simplify streaming ingestion on AWS series, we discuss how to develop an end-to-end streaming ingestion solution using [EventBridge](https://aws.amazon.com/eventbridge/), [Lambda](https://aws.amazon.com/lambda/), [MSK](https://aws.amazon.com/msk/) and [Redshift Serverless](https://aws.amazon.com/redshift/redshift-serverless/) on AWS.
- [Simplify Streaming Ingestion on AWS – Part 2 MSK and Athena](https://jaehyeon.me/blog/2023-03-14-simplify-streaming-ingestion-athena/)
  - In Part 1, we discussed a streaming ingestion solution using [EventBridge](https://aws.amazon.com/eventbridge/), [Lambda](https://aws.amazon.com/lambda/), [MSK](https://aws.amazon.com/msk/) and [Redshift Serverless](https://aws.amazon.com/redshift/redshift-serverless/). Athena provides the [MSK connector](https://docs.aws.amazon.com/athena/latest/ug/connectors-msk.html) to enable SQL queries on Apache Kafka topics directly and it can also facilitate the extraction of insights without setting up an additional pipeline to store data into S3. In this post, we discuss how to update the streaming ingestion solution so that data in the Kafka topic can be queried by Athena instead of Redshift.
- [Integrate Glue Schema Registry With Your Python Kafka App](https://jaehyeon.me/blog/2023-04-12-integrate-glue-schema-registry/)
  - [Glue Schema Registry](https://docs.aws.amazon.com/glue/latest/dg/schema-registry.html) provides a centralized repository for managing and validating schemas for topic message data. Its features can be utilized by many AWS services when building data streaming applications. In this post, we will discuss how to integrate Python Kafka producer and consumer apps in AWS Lambda with the Glue Schema Registry.
- Kafka Development with Docker
  - Apache Kafka is one of the key technologies for [modern data streaming architectures](https://docs.aws.amazon.com/whitepapers/latest/build-modern-data-streaming-analytics-architectures/build-modern-data-streaming-analytics-architectures.html) on AWS. Developing and testing Kafka-related applications can be easier using [Docker](https://www.docker.com/) and [Docker Compose](https://docs.docker.com/compose/). In this series of posts, I will demonstrate reference implementations of those applications in Dockerized environments.
    - [Part 1 Cluster Setup](https://jaehyeon.me/blog/2023-05-04-kafka-development-with-docker-part-1/)
    - Part 2 Management App
    - Part 3 Kafka Connect
    - Part 4 Produce/Consume Messages
    - Part 5 Glue Schema Registry
    - Part 6 Kafka Connect with Glue Schema Registry
    - Part 7 Produce/Consume Messages with Glue Schema Registry
    - Part 8 SSL Encryption
    - Part 9 SSL Authentication
    - Part 10 SASL Authentication
    - Part 11 Kafka Authorization
