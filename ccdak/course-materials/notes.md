## Archetecture

How do Kafka brokers ensure great performance between the producers and consumers?

- it does not transform the messages
- it leverages zero-copy optimisation to send data straight from the page-cache

If I supply the setting `compression.type=snappy` to my producer, what will happen?

- the producer/consumer have to compress the data
- Kafka transfers data with zero copy and no transformation. Any transformation (including compression) is the responsibility of clients.

If you enable an SSL endpoint in Kafka, what feature of Kafka will be lost?

- zero copy
- With SSL, messages will need to be encrypted and decrypted, by being first loaded into the JVM, so you lose the zero copy optimization. See more information here: https://twitter.com/ijuma/status/1161303431501324293?s=09

The Controller is a broker that is...

- is responsible for partition leader election
- elected by Zookeeper ensemble

What happens when `broker.rack` configuration is provided in broker configuration in Kafka cluster?

- replicas for a partition are spread across different racks
- Partitions for newly created topics are assigned in a rack alternating manner, this is the only change `broker.rack` does

Which of the following is true regarding thread safety in the Java Kafka Clients?

- one producer can be safely used in multiple threads
- one consumer needs to run in one threads
- KafkaConsumer is not thread-safe, KafkaProducer is thread safe.

In Kafka, every broker...

- contains only a subset of the topics and the partitions
- knows all the metadata for all topics and partitions
- is a bootstrap broker

How much should be the heap size of a broker in a production setup on a machine with 256 GB of RAM, in PLAINTEXT mode?

- 4 GB
- In Kafka, a small heap size is needed, while the rest of the RAM goes automatically to the page cache (managed by the OS). The heap size goes slightly up if you need to enable SSL

What is true about Kafka brokers and clients from version 0.10.2 onwards?

- New broker can communicate with older clients.
- New client can communicate with older brokers. (new)
- A newer client can talk to a newer broker, and an old client talk to a newer broker
- Kafka's new bidirectional client compatibility introduced in 0.10.2 allows this. Read more here: https://www.confluent.io/blog/upgrading-apache-kafka-clients-just-got-easier/

By default, which replica will be elected as a partition leader?

- preferred leader broker if it is in-sync and `auto.leader.rebalance.enable=true`
- an in-sync replica (as long as `unclean.leader.election=false`)

What is not a valid authentication mechanism in Kafka?

- SAML
- (valid) SASL/SCRAM, SSL, SSAL/GSSAPI
- Learn more about security here: https://kafka.apache.org/documentation/#security

## Topic/Config

Select all that applies

- `min.insync.replicas` is a topic (or broker) setting
- `min.insync.replicas` only matters if `acks=all`
- `acks` is a producer setting

A producer application in a developer machine was able to send messages to a Kafka topic. After copying the producer application into another developer's machine, the producer is able to connect to Kafka but unable to produce to the same Kafka topic because of an authorization issue. What is the likely issue?

- Kafka ACL does not allow another machine IP
- ACLs take "Host" as a parameter, which represents an IP. It can be `\*` (all IP), or a specific IP. Here, it's a specific IP as moving a producer to a different machine breaks the consumer, so the ACL needs to be updated

Compaction is enabled for a topic in Kafka by setting `log.cleanup.policy=compact`. What is true about log compaction?

- After cleanup, only one message per key is retained with the latest value

How often is log compaction evaluated?

- every time a segment is closed
- Log compaction is evaluated every time a segment is closed. It will be triggered if enough data is "dirty" (see dirty ratio config)

Your topic is log compacted and you are sending a message with the key K and value null. What will happen?

- The broker will delete all messages with the key K upon cleanup
- Sending a message with the null value is called a tombstone in Kafka and will ensure the log compacted topic does not contain any messages with the key K upon compaction

When `auto.create.topics.enable` is set to true in Kafka configuration, what are the circumstances under which a Kafka broker automatically creates a topic?

- When a producer starts writing messages to the topic
- When a consumer starts reading messages from the topic
- When any client requests metadata for the topic

What's a Kafka partition made of?

- one file and two indexes per segment
- Kafka partitions are made of segments (usually each segment is 1GB), and each segment has two corresponding indexes (offset index and time index)

Which of the following statements are true regarding the number of partitions of a topic?

- we can add partitions of a topic using the kafka-topics.sh command
- `kafka-topics.sh --bootstrap-server localhost:9092 --alter --topic test --partitions 4`

There are five brokers in a cluster, a topic with 10 partitions and replication factor of 3, and a quota of `producer_bytes_rate` of 1 MB/sec has been specified for the client. What is the maximum throughput allowed for the client?

- 5 MB/s
- Each producer is allowed to produce 1 MB/s to a broker. Max throughput `5 * 1 MB`, because we have 5 brokers.

## CLI

How do you create a topic named test with 3 partitions and 3 replicas using the Kafka CLI?

- `kafka-topics.sh --bootstrap-server localhost:9092 --create --topic test --partitions 3 --replication-factor 3`

How will you find out all the partitions where one or more of the replicas for the partition are not in-sync with the leader?

- `kafka-topic.sh --zookeeper localhost:2181 --describe --under-replicated-partitions`

How will you find out all the partitions without a leader?

- `kafka-topics.sh --zookeeper localhost:2181 --describe --unavailable-partitions`
- as of Kafka 2.2, the --zookeeper option is deprecated and you can now use
  - `kafka-topics.sh --bootstrap-server localhost:9092 --describe --unavailable-partitions`

The kafka-console-consumer CLI, when used with the default options

- uses a random group id

## Zookeeper

A Zookeeper ensemble contains 3 servers. Over which ports the members of the ensemble should be able to communicate in default configuration?

- 2181, 2888, 3888
- 2181 - client port, 2888 - peer port, 3888 - leader port

What information is stored in zookeeper?

- controller registration
- broker registration info
- ACL information

Where are the ACLs stored in a Kafka cluster by default?

- under zookeeper node `/kafka-acl/`

Where are the dynamic configurations for a topic stored?

- in Zookeeper

A Zookeeper ensemble contains 5 servers. What is the maximum number of servers that can go missing and the ensemble still run?

- 2 (majority consists of 3 zk nodes for 5 nodes zk cluster, so 2 can fail)

You have a Zookeeper cluster that needs to be able to withstand the loss of 2 servers and still be able to function. What size should your Zookeeper cluster have?

- 5 (`2*N + 1`)

A Zookeeper configuration has tickTime of 2000, initLimit of 20 and syncLimit of 5. What's the timeout value for followers to connect to Zookeeper?

- 2,000 x 20 = 40,000 ms = 40 s

What are the requirements for a Kafka broker to connect to a Zookeeper ensemble?

- all brokers must share the same `zookeeper.connect` parameter
- unique values for each broker's `broker.id` parameter

## Producer

A kafka topic has a replication factor of 3 and `min.insync.replicas` setting of 1. What is the maximum number of brokers that can be down so that a producer with `acks=all` can still produce to the topic?

- 2

Which of the following setting increases the chance of batching for a Kafka Producer?

- increase `linger.ms`
- `linger.ms` forces the producer to wait before sending messages, hence increasing the chance of creating batches that can be heavily compressed.

To enhance compression, I can increase the chances of batching by using

- `linger.ms=20`

Your producer is producing at a very high rate and the batches are completely full each time. How can you improve the producer throughput?

- enable compression and increase `batch.size`
- `linger.ms` will have no effect as the batches are already full

Which of the following errors are retriable from a producer perspective?

- RETRIABLE
  - NOT_LEADER_FOR_PARTITION
  - NOT_ENOUGH_REPLICAS
- NOT RETRIABLE
  - INVALID_REQUIRED_ACKS
  - MESSAGE_TOO_LARGE
  - TOPIC_AUTHORIZATION_FAILED

A topic has three replicas and you set `min.insync.replicas` to 2. If two out of three replicas are not available, what happens when a produce request with `acks=all` is sent to broker?

- `NotEnoughReplicasException` will be returned
- With this configuration, a single in-sync replica becomes read-only. Produce request will receive `NotEnoughReplicasException`.

A Kafka producer application wants to send log messages to a topic that does not include any key. What are the properties that are mandatory to configure for the producer configuration?

- bootstrap.servers, key.serializer, value.serializer

If I produce to a topic that does not exist, and the broker setting `auto.create.topic.enable=true`, what will happen?

- Kafka will automatically create the topic with the broker settings `num.partitions` and `default.replication.factor`

What is the risk of increasing `max.in.flight.requests.per.connection` while also enabling retries in a producer?

- message order not preserved
- Some messages may require multiple retries. If there are more than 1 requests in flight, it may result in messages received out of order. Note an exception to this rule is if you enable the producer setting: `enable.idempotence=true` which takes care of the out of ordering case on its own. See: https://issues.apache.org/jira/browse/KAFKA-5494

To prevent network-induced duplicates when producing to Kafka, I should use

- `enable.idempotence=true`
- Producer idempotence helps prevent the network introduced duplicates. More details here: https://cwiki.apache.org/confluence/display/KAFKA/Idempotent+Producer

What is returned by a producer.send() call in the Java API?

- `Future<RecordMetadata> object`

When is the onCompletion() method called?

```
private class ProducerCallback implements Callback {
         @Override
        public void onCompletion(RecordMetadata recordMetadata, Exception e) {
         if (e != null) {
             e.printStackTrace();
            }
        }
}
ProducerRecord<String, String> record = new ProducerRecord<>("topic1", "key1", "value1");
producer.send(record, new ProducerCallback());
```

- when the broker response is received

A producer application was sending messages to a partition with a replication factor of 2 by connecting to Broker 1 that was hosting partition leader. If the Broker 1 goes down, what will happen?

- the producer will automatically produce to the broker that has been elected leader
- Once the client connects to any broker, it is connected to the entire cluster and in case of leadership changes, the clients automatically do a Metadata Request to an available broker to find out who is the new leader for the topic. Hence the producer will automatically keep on producing to the correct Kafka Broker

What exceptions may be caught by the following producer? (select two)

```
ProducerRecord<String, String> record = new ProducerRecord<>("topic1", "key1", "value1");
try {
    producer.send(record);
} catch (Exception e) {
    e.printStackTrace();
}
```

- `SerializationException` and `BufferExhaustedException`
- These are the client side exceptions that may be encountered before message is sent to the broker, and before a future is returned by the .send() method.

What happens if you write the following code in your producer? `producer.send(producerRecord).get()`

- throughput will be decreased
- Using Future.get() to wait for a reply from Kafka will limit throughput.

You are receiving orders from different customer in an "orders" topic with multiple partitions. Each message has the customer name as the key. There is a special customer named ABC that generates a lot of orders and you would like to reserve a partition exclusively for ABC. The rest of the message should be distributed among other partitions. How can this be achieved?

- create a custom partitioner
- A Custom Partitioner allows you to easily customise how the partition number gets computed from a source message.

## Consumer

We would like to be in an at-most once consuming scenario. Which offset commit strategy would you recommend?

- commit the offsets in kafka before processing the data
- note: don't commit until processed if at-least once processing

```
while (true) {
          ConsumerRecords<String, String> records = consumer.poll(100);
           try {
            consumer.commitSync();
          } catch (CommitFailedException e) {
              log.error("commit failed", e)
          }
          for (ConsumerRecord<String, String> record : records)
          {
              System.out.printf("topic = %s, partition = %s, offset =%d, customer = %s, country =%s",
                  record.topic(), record.partition(),
                  record.offset(), record.key(), record.value());
          }
  }
```

A client connects to a broker in the cluster and sends a fetch request for a partition in a topic. It gets an exception `NotLeaderForPartitionException` in the response. How does client handle this situation?

- send metadata request to the same broker for the topic and select the broker hosting the leader replica

A producer just sent a message to the leader broker for a topic partition. The producer used `acks=1` and therefore the data has not yet been replicated to followers. Under which conditions will the consumer see the message?

- when the high watermark has advanced
- The high watermark is an advanced Kafka concept, and is advanced once all the ISR replicates the latest offsets. A consumer can only read up to the value of the High Watermark (which can be less than the highest offset, in the case of acks=1)

A consumer wants to read messages from partitions 0 and 1 of a topic topic1. Code snippet is shown below.

```
consumer.subscribe(Arrays.asList("topic1"));
List<TopicPartition> pc = new ArrayList<>();
pc.add(new PartitionTopic("topic1", 0));
pc.add(new PartitionTopic("topic1", 1));
consumer.assign(pc);
```

- throws `IllegalStateException`

In the Kafka consumer metrics it is observed that fetch-rate is very high and each fetch is small. What steps will you take to increase throughput?

- increase `fetch.min.bytes`

You are doing complex calculations using a machine learning framework on records fetched from a Kafka topic. It takes more about 6 minutes to process a record batch, and the consumer enters rebalances even though it's still running. How can you improve this scenario?

- increase `max.poll.interval.ms` to 600000

You have a consumer group of 12 consumers and when a consumer gets killed by the process management system, rather abruptly, it does not trigger a graceful shutdown of your consumer. Therefore, it takes up to 10 seconds for a rebalance to happen. The business would like to have a 3 seconds rebalance time. What should you do?

- decrease `session.timeout.ms` and `heartbeat.interval.ms`
- `session.timeout.ms` must be decreased to 3 seconds to allow for a faster rebalance, and the heartbeat thread must be quicker, so we also need to decrease `heartbeat.interval.ms`

How does a consumer commit offsets in Kafka?

- it interacts with the Group Coordinator broker

Which actions will trigger partition rebalance for a consumer group?

- a consumer in a consumer group shuts down (or removed)
- add a new consumer to consumer group
- increase partitions to a topic

A topic has three replicas and you set `min.insync.replicas` to 2. If two out of three replicas are not available, what happens when a consume request is sent to broker?

- data will be returned from the remaining in-sync replica
- note record cannot be produced in this situation

You are building a consumer application that processes events from a Kafka topic. What is the most important metric to monitor to ensure real-time processing?

- `records-lag-max`

How can you gracefully make a Kafka consumer to stop immediately polling data from Kafka and gracefully shut down a consumer application?

- call `consumer.wakeUp()` and catch a `WakeUpException`
- See https://stackoverflow.com/a/37748336/3019499

A consumer starts and has `auto.offset.reset=none`, and the topic partition currently has data for offsets going from 45 to 2311. The consumer group has committed the offset 10 for the topic before. Where will the consumer read from?

- `auto.offset.reset=none` means that the consumer will crash if the offsets it's recovering from have been deleted from Kafka, which is the case here, as 10 < 45

A consumer is configured with `enable.auto.commit=false`. What happens when close() is called on the consumer object?

- a rebalance in the consumer group will happen immediately
- Calling close() on consumer immediately triggers a partition rebalance as the consumer will not be available anymore.

## Schema Registry

Using the Confluent Schema Registry, where are Avro schema stored?

- in the `_schemas` topic

What are features of the Confluent schema registry?

- store schemas and enforce compatibility rules

I am producing Avro data on my Kafka cluster that is integrated with the Confluent Schema Registry. After a schema change that is incompatible, I know my data will be rejected. Which component will reject the data?

- The Confluent Schema Registry
- Kafka Brokers do not look at your payload and your payload schema, and therefore will not reject data

Which of the following is not an Avro primitive type?

- date (logical type)
- int, string, null, long (primitive type)

In Avro, adding a field to a record without default is a `__` schema evolution

- forward
- clients with old schema will be able to read records saved with new schema.

In Avro, removing a field that does not have a default is a `__` schema evolution

- backward
- clients with new schema will be able to read records saved with old schema.

In Avro, removing or adding a field that has a default is a `__` schema evolution

- full
- Clients with new schema will be able to read records saved with old schema and clients with old schema will be able to read records saved with new schema.

In Avro, adding an element to an enum without a default is a `__` schema evolution

- breaking
- (<1.9.1) if both are enums:
  - if the writer's symbol is not present in the reader's enum, then an error is signalled.
- (>=1.9.1) if both are enums:
  - if the writer's symbol is not present in the reader's enum and the reader has a default value, then that value is used, otherwise an error is signalled.

## Connect

What are internal Kafka Connect topics?

- connect-offsets, connect-configs, connect-status

You want to sink data from a Kafka topic to S3 using Kafka Connect. There are 10 brokers in the cluster, the topic has 2 partitions with replication factor of 3. How many tasks will you configure for the S3 connector?

- 2

You are using JDBC source connector to copy data from 2 tables to two Kafka topics. There is one connector created with `max.tasks` equal to 2 deployed on a cluster of 3 workers. How many tasks are launched?

- 2

When using plain JSON data with Connect, you see the following error message:

`org.apache.kafka.connect.errors.DataException: JsonDeserializer with schemas.enable requires "schema" and "payload" fields and may not contain additional fields.`

How will you fix the error?

- set `key.converter.schemas.enable` and `value.converter.schemas.enable` to false
- You will need to set the `schemas.enable` parameters for the converter to false for plain text with no schema.

## Stream/KSQL

Which Streams operators are stateful?

- aggregate, reduce, joining, count

Which of the following Kafka Streams operators are stateless?

- filter, flatmap, branch, map, groupby

The exactly once guarantee in the Kafka Streams is for which flow of data?

- kafka => kafka

How will you read all the messages from a topic in your KSQL query?

- use KSQL CLI to set `auto.offset.reset` property to earliest

In Kafka Streams, by what value are internal topics prefixed by?

- `application.id`
- In Kafka Streams, the `application.id` is also the underlying `group.id` for your consumers, and the prefix for all internal topics (repartition and state)

Where are KSQL-related data and metadata stored?

- kafka topics
- metadata is stored in and built from the KSQL command topic. Each KSQL server has its own in-memory version of the metastore.

What is an adequate topic configuration for the topic word-count-output?

```
StreamsBuilder builder = new StreamsBuilder();
KStream<String, String> textLines = builder.stream("word-count-input");
KTable<String, Long> wordCounts = textLines
        .mapValues(textLine -> textLine.toLowerCase())
        .flatMapValues(textLine -> Arrays.asList(textLine.split("\W+")))
        .selectKey((key, word) -> word)
        .groupByKey()
        .count(Materialized.as("Counts"));
wordCounts.toStream().to("word-count-output", Produced.with(Serdes.String(), Serdes.Long()));
builder.build();
```

- `cleanup.policy=compact`

Select the Kafka Streams joins that are always windowed joins.

- KStream-KStream join

We want the average of all events in every five-minute window updated every minute. What kind of Kafka Streams window will be required on the stream?

- hopping window

What is the default port that the KSQL server listens on?

- 8088

Your streams application is reading from an input topic that has 5 partitions. You run 5 instances of your application, each with `num.streams.threads` set to 5. How many stream tasks will be created and how many will be active?

- 25 created, 5 active
- One partition is assigned a thread, so only 5 will be active, and 25 threads (i.e. tasks) will be created

## Rest Proxy

If I want to send binary data through the REST proxy to topic "test_binary", it needs to be base64 encoded. A consumer connecting directly into the Kafka topic "test_binary" will receive

- binary data
- On the producer side, after receiving base64 data, the REST Proxy will convert it into bytes and then send that bytes payload to Kafka. Therefore consumers reading directly from Kafka will receive binary data.

What data format isn't natively available with the Confluent REST Proxy?

- protobuf but may use binary format instead
- binary, avro and json are supported

If I want to send binary data through the REST proxy, it needs to be base64 encoded. Which component needs to encode the binary data into base 64?

- producer
- REST Proxy requires to receive data over REST that is already base64 encoded, hence it is the responsibility of the producer

## Additional Notes

Some Important Producer Metrics

- `response-rate` (global and per broker): Responses (acks) received per second. Sudden changes in this value could
  signal a problem, though what the problem could depends on your configuration.
- `request-rate` (global and per broker): Average requests sent per second. Requests can contain multiple records,
  so this is not the number of records. It does give you part of the overall throughput picture.
- `request-latency-avg` (per broker): Average request latency in ms. High latency could be a sign of performance
  issues, or just large batches.
- `outgoing-byte-rate` (global and per broker): Bytes sent per second. Good picture of your network throughput.
  Helps with network planning.
- `io-wait-time-ns-avg` (global only): Average time spent waiting for a socket ready for reads/writes in nanoseconds.
  High wait times might mean your producers are producing more data than the cluster can accept and process.

Some Important Consumer Metrics

- `records-lag-max`: Maximum record lag. How far the consumer is behind producers. In a situation where real-time
  processing is important, high lag might mean you need more consumers.
- `bytes-consumed-rate`: Rate of bytes consumed per second. Gives a good idea of throughput.
- `records-consumed-rate`: Rate of records consumed per second.
- `fetch-rate`: Fetch requests per second. If this falls suddenly or goes to zero, it may be an indication of problems
  with the consumer

Producer Tuning

- `acks`
- `retries` (note `max.in.flight.requests.per.connection`)
- `batch.size`

Consumer Tuning

- `fetch.min.bytes`
- `heartbeat.interval.ms`
- `auto.offset.reset`
- `enable.auto.commit`
