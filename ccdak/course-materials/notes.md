### Archetecture

How do Kafka brokers ensure great performance between the producers and consumers?

- it does not transform the messages
- it leverages zero-copy optimisation to send data straight from the page-cache

### CLI

How will you find out all the partitions where one or more of the replicas for the partition are not in-sync with the leader?

- `kafka-topic.sh --zookeeper localhost:2181 --describe --under-replicated-partitions`

### Zookeeper

A Zookeeper ensemble contains 3 servers. Over which ports the members of the ensemble should be able to communicate in default configuration?

- 2181, 2888, 3888
- 2181 - client port, 2888 - peer port, 3888 - leader port

What information is stored in zookeeper?

- controller registration
- broker registration info
- ACL information

### Configuration

A kafka topic has a replication factor of 3 and min.insync.replicas setting of 1. What is the maximum number of brokers that can be down so that a producer with acks=all can still produce to the topic?

- 2

To enhance compression, I can increase the chances of batching by using - linger.ms=20
Which of the following setting increases the chance of batching for a Kafka Producer? - increase linger.ms

- linger.ms forces the producer to wait before sending messages, hence increasing the chance of creating batches that can be heavily compressed.

Your producer is producing at a very high rate and the batches are completely full each time. How can you improve the producer throughput?

- enable compression and increase `batch.size`
- `linger.ms` will have no effect as the batches are already full

Where are the dynamic configurations for a topic stored?

- in Zookeeper

A client connects to a broker in the cluster and sends a fetch request for a partition in a topic. It gets an exception NotLeaderForPartitionException in the response. How does client handle this situation?

- send metadata request to the same broker for the topic and select the broker hosting the leader replica

A Kafka producer application wants to send log messages to a topic that does not include any key. What are the properties that are mandatory to configure for the producer configuration?

- bootstrap.servers, key.serializer, value.serializer

If I produce to a topic that does not exist, and the broker setting auto.create.topic.enable=true, what will happen?

- Kafka will automatically create the topic with the broker settings num.partitions and default.replication.factor

What is the risk of increasing max.in.flight.requests.per.connection while also enabling retries in a producer?

- message order not preserved
- Some messages may require multiple retries. If there are more than 1 requests in flight, it may result in messages received out of order. Note an exception to this rule is if you enable the producer setting: enable.idempotence=true which takes care of the out of ordering case on its own. See: https://issues.apache.org/jira/browse/KAFKA-5494

Select all that applies

- min.insync.replicas is a topic (or broker) setting
- min.insync.replicas only matters if acks=all
- acks is a producer setting

Where are the ACLs stored in a Kafka cluster by default?

- under zookeeper node `/kafka-acl/`

Which of the following errors are retriable from a producer perspective?

- RETRIABLE
  - NOT_LEADER_FOR_PARTION
  - NOT_ENOUGH_REPLICAS
- NOT
  - INVALID_REQUIRED_ACKS
  - MESSAGE_TOO_LARGE
  - TOPIC_AUTHORIZATION_FAILED

We would like to be in an at-most once consuming scenario. Which offset commit strategy would you recommend?

- commit the offsets in kafka before processing the data

### Schema Registry

Using the Confluent Schema Registry, where are Avro schema stored?

- in the `_schemas` topic

What are features of the Confluent schema registry?

- store schemas and enforce compatibility rules

In Avro, adding a field to a record without default is a `__` schema evolution

- forward
- clients with old schema will be able to read records saved with new schema.

I am producing Avro data on my Kafka cluster that is integrated with the Confluent Schema Registry. After a schema change that is incompatible, I know my data will be rejected. Which component will reject the data?

- The Confluent Schema Registry
- Kafka Brokers do not look at your payload and your payload schema, and therefore will not reject data

### Connect

What are internal Kafka Connect topics?

- connect-offsets, connect-configs, connect-status

You want to sink data from a Kafka topic to S3 using Kafka Connect. There are 10 brokers in the cluster, the topic has 2 partitions with replication factor of 3. How many tasks will you configure for the S3 connector?

- 2

You are using JDBC source connector to copy data from 2 tables to two Kafka topics. There is one connector created with max.tasks equal to 2 deployed on a cluster of 3 workers. How many tasks are launched?

- 2

### Stream/KSQL

Which Streams operators are stateful?

- aggregate, reduce, joining, count

The exactly once guarantee in the Kafka Streams is for which flow of data?

- kafka => kafka

How will you read all the messages from a topic in your KSQL query?

- use KSQL CLI to set `auto.offset.reset` property to earliest

### Rest Proxy

If I want to send binary data through the REST proxy to topic "test_binary", it needs to be base64 encoded. A consumer connecting directly into the Kafka topic "test_binary" will receive

- binary data
- On the producer side, after receiving base64 data, the REST Proxy will convert it into bytes and then send that bytes payload to Kafka. Therefore consumers reading directly from Kafka will receive binary data.
