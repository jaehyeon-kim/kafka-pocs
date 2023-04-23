## Archetecture

How do Kafka brokers ensure great performance between the producers and consumers?

- it does not transform the messages
- it leverages zero-copy optimisation to send data straight from the page-cache

The Controller is a broker that is...

- is responsible for partition leader election
- elected by Zookeeper ensemble

## Topic/Config

Select all that applies

- min.insync.replicas is a topic (or broker) setting
- min.insync.replicas only matters if acks=all
- acks is a producer setting

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

## CLI

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

- 5 (2\*N + 1)

## Producer

A kafka topic has a replication factor of 3 and min.insync.replicas setting of 1. What is the maximum number of brokers that can be down so that a producer with acks=all can still produce to the topic?

- 2

To enhance compression, I can increase the chances of batching by using - linger.ms=20
Which of the following setting increases the chance of batching for a Kafka Producer? - increase linger.ms

- linger.ms forces the producer to wait before sending messages, hence increasing the chance of creating batches that can be heavily compressed.

Your producer is producing at a very high rate and the batches are completely full each time. How can you improve the producer throughput?

- enable compression and increase `batch.size`
- `linger.ms` will have no effect as the batches are already full

Your producer is producing at a very high rate and the batches are completely full each time. How can you improve the producer throughput?

- enable compression and increase `batch.size`
- `linger.ms` will have no effect as the batches are already full

Which of the following errors are retriable from a producer perspective?

- RETRIABLE
  - NOT_LEADER_FOR_PARTION
  - NOT_ENOUGH_REPLICAS
- NOT
  - INVALID_REQUIRED_ACKS
  - MESSAGE_TOO_LARGE
  - TOPIC_AUTHORIZATION_FAILED

A Kafka producer application wants to send log messages to a topic that does not include any key. What are the properties that are mandatory to configure for the producer configuration?

- bootstrap.servers, key.serializer, value.serializer

If I produce to a topic that does not exist, and the broker setting auto.create.topic.enable=true, what will happen?

- Kafka will automatically create the topic with the broker settings num.partitions and default.replication.factor

What is the risk of increasing max.in.flight.requests.per.connection while also enabling retries in a producer?

- message order not preserved
- Some messages may require multiple retries. If there are more than 1 requests in flight, it may result in messages received out of order. Note an exception to this rule is if you enable the producer setting: enable.idempotence=true which takes care of the out of ordering case on its own. See: https://issues.apache.org/jira/browse/KAFKA-5494

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
    ProducerRecord<String, String> record =
            new ProducerRecord<>("topic1", "key1", "value1");
    producer.send(record, new ProducerCallback());
```

- when the broker response is received

A producer application was sending messages to a partition with a replication factor of 2 by connecting to Broker 1 that was hosting partition leader. If the Broker 1 goes down, what will happen?

- the producer will automatically produce to the broker that has been elected leader
- Once the client connects to any broker, it is connected to the entire cluster and in case of leadership changes, the clients automatically do a Metadata Request to an available broker to find out who is the new leader for the topic. Hence the producer will automatically keep on producing to the correct Kafka Broker

## Consumer

We would like to be in an at-most once consuming scenario. Which offset commit strategy would you recommend?

- commit the offsets in kafka before processing the data

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

A client connects to a broker in the cluster and sends a fetch request for a partition in a topic. It gets an exception NotLeaderForPartitionException in the response. How does client handle this situation?

- send metadata request to the same broker for the topic and select the broker hosting the leader replica

A producer just sent a message to the leader broker for a topic partition. The producer used acks=1 and therefore the data has not yet been replicated to followers. Under which conditions will the consumer see the message?

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

- increase `feach.min.bytes`

You are doing complex calculations using a machine learning framework on records fetched from a Kafka topic. It takes more about 6 minutes to process a record batch, and the consumer enters rebalances even though it's still running. How can you improve this scenario?

- increase `max.poll.interval.ms` to 600000

How does a consumer commit offsets in Kafka?

- it interacts with the Group Coordinator broker

Which actions will trigger partition rebalance for a consumer group?

- a consumer in a consumer group shuts down (or removed)
- add a new consumer to consumer group
- increase partitions to a topic

A topic has three replicas and you set min.insync.replicas to 2. If two out of three replicas are not available, what happens when a consume request is sent to broker?

- data will be returned from the remaining in-sync replica
- note record cannot be produced in this situation

You are building a consumer application that processes events from a Kafka topic. What is the most important metric to monitor to ensure real-time processing?

- records-lag-max

How can you gracefully make a Kafka consumer to stop immediately polling data from Kafka and gracefully shut down a consumer application?

- call `consumer.wakeUp()` and catch a `WakeUpException`
- See https://stackoverflow.com/a/37748336/3019499

A consumer starts and has auto.offset.reset=none, and the topic partition currently has data for offsets going from 45 to 2311. The consumer group has committed the offset 10 for the topic before. Where will the consumer read from?

- auto.offset.reset=none means that the consumer will crash if the offsets it's recovering from have been deleted from Kafka, which is the case here, as 10 < 45

## Schema Registry

Using the Confluent Schema Registry, where are Avro schema stored?

- in the `_schemas` topic

What are features of the Confluent schema registry?

- store schemas and enforce compatibility rules

I am producing Avro data on my Kafka cluster that is integrated with the Confluent Schema Registry. After a schema change that is incompatible, I know my data will be rejected. Which component will reject the data?

- The Confluent Schema Registry
- Kafka Brokers do not look at your payload and your payload schema, and therefore will not reject data

In Avro, adding a field to a record without default is a `__` schema evolution

- forward
- clients with old schema will be able to read records saved with new schema.

In Avro, removing a field that does not have a default is a `__` schema evolution

- backward
- clients with new schema will be able to read records saved with old schema.

## Connect

What are internal Kafka Connect topics?

- connect-offsets, connect-configs, connect-status

You want to sink data from a Kafka topic to S3 using Kafka Connect. There are 10 brokers in the cluster, the topic has 2 partitions with replication factor of 3. How many tasks will you configure for the S3 connector?

- 2

You are using JDBC source connector to copy data from 2 tables to two Kafka topics. There is one connector created with max.tasks equal to 2 deployed on a cluster of 3 workers. How many tasks are launched?

- 2

When using plain JSON data with Connect, you see the following error message: `org.apache.kafka.connect.errors.DataException: JsonDeserializer with schemas.enable requires "schema" and "payload" fields and may not contain additional fields.` How will you fix the error?

- set `key.converter.schemas.enable` and `value.converter.schemas.enable` to false
- You will need to set the schemas.enable parameters for the converter to false for plain text with no schema.

## Stream/KSQL

Which Streams operators are stateful?

- aggregate, reduce, joining, count

The exactly once guarantee in the Kafka Streams is for which flow of data?

- kafka => kafka

How will you read all the messages from a topic in your KSQL query?

- use KSQL CLI to set `auto.offset.reset` property to earliest

In Kafka Streams, by what value are internal topics prefixed by?

- `application.id`
- In Kafka Streams, the application.id is also the underlying group.id for your consumers, and the prefix for all internal topics (repartition and state)

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

## Rest Proxy

If I want to send binary data through the REST proxy to topic "test_binary", it needs to be base64 encoded. A consumer connecting directly into the Kafka topic "test_binary" will receive

- binary data
- On the producer side, after receiving base64 data, the REST Proxy will convert it into bytes and then send that bytes payload to Kafka. Therefore consumers reading directly from Kafka will receive binary data.

What data format isn't natively available with the Confluent REST Proxy?

- protobuf but may use binary format instead
- binary, avro and json are supported
