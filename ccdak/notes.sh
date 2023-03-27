docker exec -it kafka-0 bash
cd /opt/bitnami/kafka/bin/

####
#### chapter 3
####
./kafka-topics.sh --bootstrap-server localhost:9092 --list
./kafka-topics.sh --bootstrap-server localhost:9092 \
  --create --topic my-topic --partitions 3 --replication-factor 2
./kafka-topics.sh --bootstrap-server localhost:9092 \
  --describe --topic my-topic
# Topic: my-topic TopicId: OTbVsOoOR6aUdSOuI4Ws_Q PartitionCount: 3       ReplicationFactor: 2    Configs: 
#         Topic: my-topic Partition: 0    Leader: 0       Replicas: 0,2   Isr: 0,2
#         Topic: my-topic Partition: 1    Leader: 2       Replicas: 2,1   Isr: 2,1
#         Topic: my-topic Partition: 2    Leader: 1       Replicas: 1,0   Isr: 1,0

####
#### LAB Working with Kafka from Command Line
####
# Your supermarket company has a three-broker Kafka cluster. They want to use Kafka to track purchases so they can keep track of their inventory 
# and are working on some software that will interact with the Kafka cluster to produce and consume this data.
# However, before they can start using the cluster, they need you to create a topic to handle this data. 
# You will also need to test that everything is working by publishing some data to the topic, and then address consuming it. 
# Since the application is being built, you will need to do this using Kafka's command line tools.

# Create a topic that meets the following specifications:

# The topic name should be inventory_purchases.
# Number of partitions: 6
# Replication factor: 3
# Publish some test data to the topic. Since this is just a test, the data can be anything you want, but here is an example:

# product: apples, quantity: 5
# product: lemons, quantity: 7
# Set up a consumer from the command line and verify that you see the test data you published to the topic.

# This cluster is a confluent cluster, so you can access the Kafka command line utilities directly from the path, i.e. kafka-topics.

# If you get stuck, feel free to check out the solution video, or the detailed instructions under each objective. Good luck!

## create topic
./kafka-topics.sh --bootstrap-server localhost:9092 \
  --create --topic inventory_purchases --partitions 6 --replication-factor 3
./kafka-topics.sh --bootstrap-server localhost:9092 \
  --describe --topic inventory_purchases

## produce/consume data
./kafka-console-producer.sh --bootstrap-server localhost:9092 --topic inventory_purchases

product: apples, quantity: 5
product: lemons, quantity: 7

./kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic inventory_purchases --from-beginning

####
#### LAB Consuming Kafka Messages from Multiple Consumers
####
# Your supermarket company is getting ready to use Kafka to process purchase data to track changes in inventory. 
# When a customer purchases an item, data about the name of the item and quantity purchased will be published to a topic called inventory_purchases in the Kafka cluster.
# The company is working on determining the best way to consume this data, and they want you to perform a proof-of-concept for the proposed consumer setup. 
# Your task is to set up some consumers following a specified configuration, and then examine the message data processed by these consumers. 
# Lastly, you will store some sample data that demonstrates what messages get processed by each consumer.

# The system currently is set up so that a stream of sample data gets continuously produced to the topic.

# Consume the data according to the following specifications:

# Consume the data from the inventory_purchases topic.
# Set up a consumer and wait for it to process some data.
# Store the output in /home/cloud_user/output/group1_consumer1.txt.
# Set up a separate consumer group with two consumers in that group.
# Wait for them to process some messages simultaneously.
# Store the output in /home/cloud_user/output/group2_consumer1.txt and /home/cloud_user/output/group2_consumer2.txt.
# You have been given a three-broker Kafka cluster to complete this task but should perform all of your work on Broker 1.

# If you get stuck, feel free to check out the solution video, or the detailed instructions under each objective. Good luck!
./kafka-console-producer.sh --bootstrap-server localhost:9092 --topic inventory_purchases

product: apples, quantity: 5
product: lemons, quantity: 7


# single consumer
./kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic inventory_purchases --group group1 --from-beginning
# multiple consumers
./kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic inventory_purchases --group group2 --from-beginning

####
#### chapter 4
####
git clone https://github.com/linuxacademy/content-ccdak-kafka-java-connect.git -b end-state
./gradlew run

./kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic count-topic --from-beginning

git clone https://github.com/linuxacademy/content-ccdak-kafka-simple-consumer.git -b end-state


####
#### chapter 5
####
## s5_01_basic.py
./kafka-console-producer.sh --bootstrap-server localhost:9092 --topic streams-input-topic --property parse.key=true --property key.separator=@
{"mykey":"hello"}@{"myvalue": "world"}
{"mykey":"world"}@{"myvalue": "hello"}

./kafka-console-producer.sh --bootstrap-server localhost:9092 --topic streams-input-topic --property parse.key=true --property key.separator=:
hello:world

## s5_02_stateless.py
./kafka-console-producer.sh --bootstrap-server localhost:9092 --topic stateless-transformations-input-topic --property parse.key=true --property key.separator=:
akey:avalue
akey:bvalue
bkey:avalue

## s5_03_aggregation.py
./kafka-console-producer.sh --bootstrap-server localhost:9092 --topic aggregations-input-topic --property parse.key=true --property key.separator=:

a:a
b:hello
b:world
c:hello

./kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic aggregations-output-charactercount-topic --property print.key=true \
  --property value.deserializer=org.apache.kafka.common.serialization.IntegerDeserializer

./kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic aggregations-output-count-topic --property print.key=true \
  --property value.deserializer=org.apache.kafka.common.serialization.LongDeserializer

./kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic aggregations-output-reduce-topic --property print.key=true

## s5_04_join.py
./kafka-console-producer.sh --bootstrap-server localhost:9092 --topic joins-input-topic-left --property parse.key=true --property key.separator=:
a:a
b:foo

./kafka-console-producer.sh --bootstrap-server localhost:9092 --topic joins-input-topic-right --property parse.key=true --property key.separator=:
a:a
b:bar
c:foo

## s5_05_windowing.py
./kafka-console-producer.sh --bootstrap-server localhost:9092 --topic windowing-input-topic --property parse.key=true --property key.separator=:
a:a
b:hello
b:world
c:hello
c:world

b:hello

####
#### LAB Working with Stream Processing
####
git clone -b end-state https://github.com/linuxacademy/content-ccdak-kafka-streams-lab.git

# Your supermarket company is working toward using Kafka to automate some aspects of inventory management. 
# Currently, they are trying to use Kafka to keep track of purchases so that inventory systems can be updated as items are bought. 
# So far, the company has created a Kafka topic where they are publishing information about the types and quantities of items being purchased.

# When a customer makes a purchase, a record is published to the inventory_purchases topic for each item type (i.e., "apples"). 
# These records have the item type as the key and the quantity purchased in the transaction as the value. 
# An example record would look like this, indicating that a customer bought five apples:

# apples:5

# Your task is to build a Kafka streams application that will take the data about individual item purchases 
#   and output a running total purchase quantity for each item type. 
# The output topic is called total_purchases. So, for example, with the following input from inventory_purchases:

# apples:5
# oranges:2
# apples:3

# Your streams application should output the following to total_purchases:

# apples:8
# oranges:2

# Be sure to output the total quantity as an Integer. 
# Note that the input topic has the item quantity serialized as a String, so you will need to work around this using type conversion.

# To get started, use the starter project located at https://github.com/linuxacademy/content-ccdak-kafka-streams-lab. 
# This GitHub project also contains an end-state branch with an example solution for the lab.

# You should be able to perform all work on the Broker 1 server.

# If you get stuck, feel free to check out the solution video, or the detailed instructions under each objective. Good luck!

./kafka-topics.sh --bootstrap-server localhost:9092 --create --topic inventory-purchases

./kafka-console-producer.sh --bootstrap-server localhost:9092 --topic inventory-purchases --property parse.key=true --property key.separator=:

####
#### chapter 6
####

#### Kafka Config
### Broker Config
broker config - server.properties, command line, AdminClient API

read-only - require broker restart to get updated
per-broker - can be dynamically updated for each individual broker
cluster-wide - can be dynamically updated and applies to cluster as a whole

./kafka-configs.sh --bootstrap-server localhost:9092 --entity-type brokers --entity-name 1 --describe
# Dynamic configs for broker 1 are:
# - command line only shows updated (or different from default) configs

./kafka-configs.sh --bootstrap-server localhost:9092 --entity-type brokers --entity-name 1 --alter --add-config log.cleaner.threads=2
# Completed updating config for broker 1.

./kafka-configs.sh --bootstrap-server localhost:9092 --entity-type brokers --entity-name 1 --describe
# Dynamic configs for broker 1 are:
#   log.cleaner.threads=2 sensitive=false synonyms={DYNAMIC_BROKER_CONFIG:log.cleaner.threads=2, DEFAULT_CONFIG:log.cleaner.threads=1}

### Topic Config
topic config - kafka-topics or kafka-configs

all topic configs have a broker-wide default and will be used unless overriden
use --config argument

./kafka-topics.sh --bootstrap-server localhost:9092 --create --topic configured-topic --partitions 1 --replication-factor 1 --config max.message.bytes=64000
# Created topic configured-topic.

./kafka-configs.sh --bootstrap-server localhost:9092 --entity-type topics --entity-name configured-topic --describe
# Dynamic configs for topic configured-topic are:
#   max.message.bytes=64000 sensitive=false synonyms={DYNAMIC_TOPIC_CONFIG:max.message.bytes=64000, DEFAULT_CONFIG:message.max.bytes=1048588}

# override existing config
./kafka-configs.sh --bootstrap-server localhost:9092 --entity-type topics --entity-name configured-topic --alter --add-config max.message.bytes=65000
# Completed updating config for topic configured-topic.

./kafka-configs.sh --bootstrap-server localhost:9092 --entity-type topics --entity-name configured-topic --describe
# Dynamic configs for topic configured-topic are:
#   max.message.bytes=65000 sensitive=false synonyms={DYNAMIC_TOPIC_CONFIG:max.message.bytes=65000, DEFAULT_CONFIG:message.max.bytes=1048588}

## topic config can also take broker level default, message.max.bytes is cluster-wide config
./kafka-configs.sh --bootstrap-server localhost:9092 --entity-type brokers --entity-name 1 --alter --add-config message.max.bytes=66000
# Completed updating config for broker 1.

./kafka-configs.sh --bootstrap-server localhost:9092 --entity-type brokers --entity-name 1 --describe
# Dynamic configs for broker 1 are:
#   message.max.bytes=66000 sensitive=false synonyms={DYNAMIC_BROKER_CONFIG:message.max.bytes=66000, DEFAULT_CONFIG:message.max.bytes=1048588}
#   log.cleaner.threads=2 sensitive=false synonyms={DYNAMIC_BROKER_CONFIG:log.cleaner.threads=2, DEFAULT_CONFIG:log.cleaner.threads=1}

### Client Config
producer, consumer, stream, connect, admin client ... programmatically

###
### LAB Configuring Kafka Topics
###
# Your supermarket company is using Kafka to handle data related to inventory. 
# They have a topic called inventory_purchases that manages some of this data, 
# but initial testing has determined that some configuration changes are needed.

# Implement the following configuration changes in the cluster:

# For the inventory_purchases topic, it is more important to maintain availability than data consistency 
# since inventory errors can be reconciled later. 
# Turn on unclean.leader.election for the inventory_purchases topic (unclean.leader.election.enable=true).

# The majority of uses cases planned for this cluster do not require a lengthy retention period. 
# Set the default retention period for the cluster (log.retention.ms) to 3 days (259200000 ms).

# Change the retention period (retention.ms) for the existing inventory_purchases topic to 3 days (259200000 ms).

# If you get stuck, feel free to check out the solution video, or the detailed instructions under each objective. Good luck!

## create topic
./kafka-topics.sh --bootstrap-server localhost:9092 --create \
  --topic inventory_purchases --partitions 3 --replication-factor 3
# WARNING: Due to limitations in metric names, topics with a period ('.') or underscore ('_') could collide. To avoid issues it is best to use either, but not both.
# Created topic inventory_purchases.

## turn on unclean.leader.election
./kafka-configs.sh --bootstrap-server localhost:9092 --entity-type topics \
  --entity-name inventory_purchases --alter --add-config unclean.leader.election.enable=true
# Completed updating config for topic inventory_purchases.

./kafka-configs.sh --bootstrap-server localhost:9092 --entity-type topics --entity-name inventory_purchases --describe
# Dynamic configs for topic inventory_purchases are:
#   unclean.leader.election.enable=true sensitive=false synonyms={DYNAMIC_TOPIC_CONFIG:unclean.leader.election.enable=true, DEFAULT_CONFIG:unclean.leader.election.enable=false}

## update broker retention period
./kafka-configs.sh --bootstrap-server localhost:9092 --entity-type brokers --entity-name 1 \
  --alter --add-config log.retention.ms=259200000
# Completed updating config for broker 1.

./kafka-configs.sh --bootstrap-server localhost:9092 --entity-type brokers --entity-name 1 --describe
# Dynamic configs for broker 1 are:
#   log.retention.ms=259200000 sensitive=false synonyms={DYNAMIC_BROKER_CONFIG:log.retention.ms=259200000, STATIC_BROKER_CONFIG:log.retention.hours=168, DEFAULT_CONFIG:log.retention.hours=168}

## update topic retention period
./kafka-configs.sh --bootstrap-server localhost:9092 --entity-type topics \
  --entity-name inventory_purchases --alter --add-config retention.ms=259200000
# Completed updating config for topic inventory_purchases.

./kafka-configs.sh --bootstrap-server localhost:9092 --entity-type topics --entity-name inventory_purchases --describe
# Dynamic configs for topic inventory_purchases are:
#   retention.ms=259200000 sensitive=false synonyms={DYNAMIC_TOPIC_CONFIG:retention.ms=259200000}
#   unclean.leader.election.enable=true sensitive=false synonyms={DYNAMIC_TOPIC_CONFIG:unclean.leader.election.enable=true, DEFAULT_CONFIG:unclean.leader.election.enable=false}

###
### LAB Configuring Kafka Client
###
Your supermarket company has a Kafka producer application that is written in Java. 
You have been asked to implement some configuration changes in this application, and then execute it to test those changes. 
The base application code has already been written. You can clone a copy of the source code from GitHub to modify and test it. 
Implement the required configuration changes and run the program to verify that everything works as expected.

These are the configuration changes you will need to implement for the producer:

1. Set acks to all to ensure maximum data integrity in case a partition leader fails.
2. A smaller amount of memory needs to allocated for the producer to buffer messages. Set buffer.memory to 12582912 (about 12 MB).
3. The producer will need to clean up idle connections more quickly then the default setting specifies. 
Set connections.max.idle.ms to 300000 ms (5 minutes).

You can find the producer project code at https://github.com/linuxacademy/content-ccdak-kafka-client-config-lab.git. Clone this project into /home/cloud_user on Broker 1. The producer is implemented in the Main class located at src/main/java/com/linuxacademy/ccdak/client/config/Main.java.

You can execute the producer to test your changes by running this command while in the /home/cloud_user/content-ccdak-kafka-client-config-lab directory:

./gradlew run
If you want to view the output data published to the topic by the publisher, then use this command:

kafka-console-consumer --bootstrap-server localhost:9092 --topic inventory_purchases --property print.key=true --from-beginning
If you get stuck, feel free to check out the solution video, or the detailed instructions under each objective. Good luck!

# public class Main {
#     public static void main(String[] args) {
#         Properties props = new Properties();
#         props.put("bootstrap.servers", "localhost:9092");
#         props.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer");
#         props.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer");
        
#         props.put("acks", "all");
#         props.put("buffer.memory", "12582912");
#         props.put("connections.max.idle.ms", "300000");
        
#         Producer<String, String> producer = new KafkaProducer<>(props);
#         producer.send(new ProducerRecord<>("inventory_purchases", "apples", "1"));
#         producer.send(new ProducerRecord<>("inventory_purchases", "apples", "3"));
#         producer.send(new ProducerRecord<>("inventory_purchases", "oranges", "12"));
#         producer.send(new ProducerRecord<>("inventory_purchases", "bananas", "25"));
#         producer.send(new ProducerRecord<>("inventory_purchases", "pears", "15"));
#         producer.send(new ProducerRecord<>("inventory_purchases", "apples", "6"));
#         producer.send(new ProducerRecord<>("inventory_purchases", "pears", "7"));
#         producer.send(new ProducerRecord<>("inventory_purchases", "oranges", "1"));
#         producer.send(new ProducerRecord<>("inventory_purchases", "grapes", "56"));
#         producer.send(new ProducerRecord<>("inventory_purchases", "oranges", "11"));
#         producer.close();
#     }
# }

####
#### chapter 7
####

###
### LAB Building a Kafka Producer
###

# Your supermarket company is using Kafka to manage data related to inventory. 
# They have some files containing data about transactions and want you to build a producer 
#   that is capable of reading these files and publishing the data to Kafka.

# There is a sample transaction log file containing an example of some of this data. 
# The file contains data in the format <product>:<quantity>, for example: apples:5. 
# Each line in the file represents a new transaction. 

# Build a producer that reads each line in the file and publishes a record to the inventory_purchases topic. 
# Use the product name as the key and the quantity as the value.

# The company also wants to track purchases of apples in a separate topic (in addition to the inventory_purchases topic). 
# So, for records that have a key of apples, publish them both to the inventory_purchases and the apple_purchases topic.

# Finally, to maintain maximum data integrity set acks to all for your producer.

# There is a starter project located in GitHub which you can use to implement your producer: https://github.com/linuxacademy/content-ccdak-kafka-producer-lab.git. 

# Clone this project and implement the producer in its Main class. 
# You can execute the main class from the project directory with the ./gradlew run command.

# The sample transaction log file can be found inside the starter project at src/main/resources/sample_transaction_log.txt.

# If you get stuck, feel free to check out the solution video, or the detailed instructions under each objective. Good luck!

###
### LAB Building a Kafka Consumer
###

# Your supermarket company is using Kafka to process inventory data. 
# They have a topic called inventory_purchases which is receiving data about the items being purchased and the quantity. 
# However, there is still a legacy system which must ingest this data in the form of a data file.

# You have been asked to create a consumer that will read the data from the topic and output to a data file. 
# Each record should be on its own line, and should have the following format:

# key=<key>, value=<value>, topic=<topic>, partition=<partition>, offset=<offset>

# There is a starter project located in GitHub which you can use to implement your producer: https://github.com/linuxacademy/content-ccdak-kafka-consumer-lab.git. Clone this project and implement the consumer in its Main class. You can execute the main class from the project directory with the ./gradlew run command.

# The output data should go into the following file: /home/cloud_user/output/output.dat.

# If you get stuck, feel free to check out the solution video, or the detailed instructions under each objective. Good luck!

####
#### chapter 8
####
# https://docs.confluent.io/5.2.4/quickstart/ce-docker-quickstart.html
# https://github.com/confluentinc/cp-all-in-one/blob/7.3.0-post/cp-all-in-one/docker-compose.yml
# https://docs.confluent.io/platform/current/kafka-rest/quickstart.html

### producing message
./kafka-topics.sh --bootstrap-server localhost:9092 --create \
  --topic jsontest --partitions 1 --replication-factor 1

curl -X POST \
  -H "Content-Type: application/vnd.kafka.json.v2+json" \
  --data '{"records": [{"key": "message", "value": "Hello"}, {"key": "message", "value": "World"}]}' \
  "http://localhost:8082/topics/jsontest"
# {"offsets":[{"partition":0,"offset":0,"error_code":null,"error":null},{"partition":0,"offset":1,"error_code":null,"error":null}],"key_schema_id":null,"value_schema_id":null}

./kafka-console-consumer.sh --bootstrap-server localhost:9092 \
  --topic jsontest --from-beginning --property print.key=true

### consuming messages
# 1. create a consumer (jsontest) and consumer instance (jsontest_instance)
curl -X POST \
  -H "Content-Type: application/vnd.kafka.v2+json" \
  --data '{"name": "jsontest_instance", "format": "json", "auto.offset.reset": "earliest"}' \
  http://localhost:8082/consumers/jsontest
# {"instance_id":"jsontest_instance","base_uri":"http://localhost:8082/consumers/jsontest/instances/jsontest_instance"}

# 2. subscribe the consumer instance to a topic - can subscribe multiple topics
curl -X POST \
  -H "Content-Type: application/vnd.kafka.v2+json" \
  --data '{"topics":["jsontest"]}' \
  http://localhost:8082/consumers/jsontest/instances/jsontest_instance/subscription

# 3. consume messages
curl -X GET \
  -H "Accept: application/vnd.kafka.json.v2+json" \
  http://localhost:8082/consumers/jsontest/instances/jsontest_instance/records
# [{"topic":"jsontest","key":"message","value":"Hello","partition":0,"offset":0},{"topic":"jsontest","key":"message","value":"World","partition":0,"offset":1}]

# 4. close consumer
curl -X DELETE \
  -H "Content-Type: application/vnd.kafka.v2+json" \
  http://localhost:8082/consumers/jsontest/instances/jsontest_instance

###
### LAB Producing Kafka Messages with Confluent REST Proxy
###
# Your supermarket company is using Kafka to handle messaging as part of its infrastructure. 
# Recently, some data was lost before it could be published to Kafka due to a power failure in a data center. 
# You have been asked to publish these lost records to the necessary topics manually. 
# Luckily, Confluent REST Proxy is installed and can be used to interact with Kafka using simple HTTP requests easily.

# Using Confluent REST Proxy, publish the following records to the Kafka cluster.

# Publish to the inventory_purchases topic:
# Key: apples, Value: 23
# Key: grapes, Value: 160

# Publish to the member_signups topic:
# Key: 77543, Value: Rosenberg, Willow
# Key: 56878, Value: Giles, Rupert

## inventory purchases
./kafka-topics.sh --bootstrap-server localhost:9092 --create \
  --topic inventory_purchases --partitions 1 --replication-factor 1

curl -X POST \
  -H "Content-Type: application/vnd.kafka.json.v2+json" \
  --data '{"records": [{"key": "apples", "value": "23"}, {"key": "grapes", "value": "160"}]}' \
  http://localhost:8082/topics/inventory_purchases

./kafka-console-consumer.sh --bootstrap-server localhost:9092 \
  --topic inventory_purchases --from-beginning --property print.key=true

## member signups
./kafka-topics.sh --bootstrap-server localhost:9092 --create \
  --topic member_signups --partitions 1 --replication-factor 1

curl -X POST \
  -H "Content-Type: application/vnd.kafka.json.v2+json" \
  --data '{"records": [{"key": "77543", "value": "Rosenberg, Willow"}, {"key": "56878", "value": "Giles, Rupert"}]}' \
  http://localhost:8082/topics/member_signups

./kafka-console-consumer.sh --bootstrap-server localhost:9092 \
  --topic member_signups --from-beginning --property print.key=true

###
### LAB Consuming Kafka Messages with Confluent REST Proxy
###
# Your supermarket company is using Kafka to handle messaging as part of its infrastructure. 
# They want to prepare a report that requires some data that is currently stored in Kafka.

# You have been asked to access the cluster and provide some data points that will be used in this report. 
# Luckily, the Confluent REST Proxy will make it easy for you to gather the necessary data using simple HTTP requests. 
# Obtain the requested data points and place them in the specified output files.

# First, the report will need to include the number of apples sold in the last week. 
# This information can be found in a topic called weekly_sales. The records in this topic represent aggregate data. 
# Find the latest record with a key of apples and write its value to the file located at /home/cloud_user/output/apple_sales.txt.

# Secondly, the report needs to include the current quarterly balance for product purchases. 
# Read from the topic called quarterly_purchases. 
# Find the latest record and write its value to the file located at /home/cloud_user/output/quarterly_balance.txt.

# If you get stuck, feel free to check out the solution video, or the detailed instructions under each objective. Good luck!

# >>> Will just read records from those that are created in the previous lab.

# 1. create a consumer
curl -X POST \
  -H "Content-Type: application/vnd.kafka.v2+json" \
  --data '{"name": "lab_instance", "format": "json", "auto.offset.reset": "earliest"}' \
  http://localhost:8082/consumers/lab

# 2. subscribe the consumer instance to topics
curl -X POST \
  -H "Content-Type: application/vnd.kafka.v2+json" \
  --data '{"topics":["inventory_purchases", "member_signups"]}' \
  http://localhost:8082/consumers/lab/instances/lab_instance/subscription

# 3. consume messages
curl -X GET \
  -H "Accept: application/vnd.kafka.json.v2+json" \
  http://localhost:8082/consumers/lab/instances/lab_instance/records
# [{"topic":"member_signups","key":"77543","value":"Rosenberg, Willow","partition":0,"offset":0},{"topic":"member_signups","key":"56878","value":"Giles, Rupert","partition":0,"offset":1},{"topic":"inventory_purchases","key":"apples","value":"23","partition":0,"offset":0},{"topic":"inventory_purchases","key":"grapes","value":"160","partition":0,"offset":1}]

# 4. close consumer
curl -X DELETE \
  -H "Content-Type: application/vnd.kafka.v2+json" \
  http://localhost:8082/consumers/lab/instances/lab_instance

####
#### chapter 9
####
# Confluent Schema Registry is a versioned, distributed storage for Apache Avro schemas.

# These schemas define an expected format for your data 
#   and can be used for serialize and deserialize complex data formats when interacting with Kafka.

# Avro schemas allow producers to specify a complex format for published data, 
#   and consumers can use the schema to interprete this data. Both communicate with the schema registry
#   to store and retrieve these schemas.

# Schemas can be applied to both keys and values in messages.

# Compatibility
# Backward
# - update consumer followed by update producer
# - because consumer w/ updated schema can read data w/ current schema
# Forward 
# - update producer followed by update consumer
# - because consumer w/ current schema can read data w/ updated schema

###
### LAB Using Schema Registry in a Kafka Application
###

# Your supermarket company is using Kafka to manage updates to inventory as purchases are made in real-time. 
# In the past, data was published to a topic in a basic format, but the company now wants to use a more complex data structure 
#   with multiple data points in each record. This is a good use case for Confluent Schema Registry. 
# Create a schema to represent the data and then build a simple producer to publish some sample data using the schema. 
# Finally, create a consumer to consume this data and output it to a data file.

# There is a starter project on GitHub at https://github.com/linuxacademy/content-ccdak-schema-registry-lab. Clone this project to the broker and edit its files to implement the solution.

# Use the following specification to build a schema called Purchase. You can place the schema file in src/main/avro/com/linuxacademy/ccdak/schemaregistry/.

# Field id with type int. This will contain the purchase id.
# Field product with type string. This will contain the name of the product purchased.
# Field quantity with type int. This will contain the quantity of the product purchased.
# Create a publisher that publishes some sample records using this schema to the inventory_purchases topic.

# Then, create a consumer to read these records and output them to a file located at /home/cloud_user/output/output.txt.

# You can run the producer in the starter project with the command ./gradlew runProducer. 
# The consumer can be run with ./gradlew runConsumer. Run both the producer and consumer to verify that everything works.

# If you get stuck, feel free to check out the solution video, or the detailed instructions under each objective. Good luck!
{
    "namespace": "com.linuxacademy.ccdak.schemaregistry",
    "type": "record",
    "name": "Purchase",
    "fields": [
        {"name": "id", "type": "int"},
        {"name": "name", "type": "string"},
        {"name": "quantity", "type": "int"},
    ],
}

###
### LAB Evolving an Avro Schema in a Kafka Application
###
Your supermarket company is using Kafka to track changes in inventory as purchases occur. 
There is a topic for this data called inventory_purchases, plus a producer and consumer that interact with that topic. 
The producer and consumer are using an Avro schema to serialize and deserialize the data.

The company has a membership program for customers, and members of the program each have a member ID. 
The company would like to start tracking this member ID with the data in inventory_purchases. 
This field should be optional, however, since not all customers participate in the membership program.

Add a new field called member_id to the Purchase schema. Make this field optional with a 0 default. 
Then, update the producer to set this new field on the records it is producing. Run the producer and consumer to verify that everything works.

The consumer writes its output to a data file located at /home/cloud_user/output/output.txt. Once all changes are made, and everything is working, you should see the member_id field reflected in the data written to that file.
There is a starter project on GitHub at https://github.com/linuxacademy/content-ccdak-schema-evolve-lab.git. Clone this project to the broker and edit its files to implement the solution.
If you get stuck, feel free to check out the solution video, or the detailed instructions under each objective. Good luck!

####
#### chapter 9
####
https://kafka.apache.org/documentation.html#connect_rest

file sink connector - https://jar-download.com/artifacts/org.apache.kafka/connect-file/2.1.0/source-code/org/apache/kafka/connect/file/FileStreamSinkConnector.java
debezium connector - https://repo1.maven.org/maven2/io/debezium/debezium-connector-postgres/2.1.3.Final/debezium-connector-postgres-2.1.3.Final-plugin.tar.gz

###
### LAB Exporting Data to a File with Kafka Connect
###
# Your supermarket company is using Kafka to manage some data. 
# They want to export data from a topic to a data file on the disk for analysis. 
# You have been asked to set up a connector to automatically export records from the inventory_purchases topic to a file 
#   located at /home/cloud_user/output/output.txt.

# Use the following information as you implement a solution:

# The connector class org.apache.kafka.connect.file.FileStreamSinkConnector can be used to export data to a file.
# Set the number of tasks to 1.
# The data in the topic is string data, so use org.apache.kafka.connect.storage.StringConverter for key.converter and value.converter.
# Here is an example of a connector configuration for a FileStream Sink Connector:

# "connector.class": "org.apache.kafka.connect.file.FileStreamSinkConnector",
# "tasks.max": "1",
# "file": "<file path>",
# "topics": "<topic>",
# "key.converter": "<key converter>",
# "value.converter": "<value converter>"
# Once you have set up the connector, publish a new record to the topic for a purchase of plums:

# kafka-console-producer --broker-list localhost:9092 --topic inventory_purchases

# plums:5
# Check the file to verify that the new record appears:

# cat /home/cloud_user/output/output.txt
# If you get stuck, feel free to check out the solution video, or the detailed instructions under each objective. Good luck!

curl -s -X GET http://localhost:8083/connector-plugins
# [{"class":"org.apache.kafka.connect.file.FileStreamSinkConnector","type":"sink","version":"3.3.2"},{"class":"org.apache.kafka.connect.file.FileStreamSourceConnector","type":"source","version":"3.3.2"},{"class":"org.apache.kafka.connect.mirror.MirrorCheckpointConnector","type":"source","version":"3.3.2"},{"class":"org.apache.kafka.connect.mirror.MirrorHeartbeatConnector","type":"source","version":"3.3.2"},{"class":"org.apache.kafka.connect.mirror.MirrorSourceConnector","type":"source","version":"3.3.2"}]

curl -X POST http://localhost:8083/connectors \
  -H 'Accept: */*' \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "file_sink_connector",
    "config": {
      "connector.class": "org.apache.kafka.connect.file.FileStreamSinkConnector",
      "tasks.max": "1",
      "topics": "connect_topic",
      "file": "/tmp/output.txt",
      "key.converter": "org.apache.kafka.connect.storage.StringConverter",
      "value.converter": "org.apache.kafka.connect.storage.StringConverter"
    }
  }'
# {"name":"file_sink_connector","config":{"connector.class":"org.apache.kafka.connect.file.FileStreamSinkConnector","tasks.max":"1","topics":"connect_topic","file":"/tmp/output.txt","key.converter":"org.apache.kafka.connect.storage.StringConverter","value.converter":"org.apache.kafka.connect.storage.StringConverter","name":"file_sink_connector"},"tasks":[],"type":"sink"}

curl http://localhost:8083/connectors/file_sink_connector
# {"name":"file_sink_connector","config":{"connector.class":"org.apache.kafka.connect.file.FileStreamSinkConnector","file":"/tmp/output.txt","tasks.max":"1","topics":"connect_topic","name":"file_sink_connector","value.converter":"org.apache.kafka.connect.storage.StringConverter","key.converter":"org.apache.kafka.connect.storage.StringConverter"},"tasks":[{"connector":"file_sink_connector","task":0}],"type":"sink"}

curl http://localhost:8083/connectors/file_sink_connector/status
# {"name":"file_sink_connector","connector":{"state":"RUNNING","worker_id":"172.31.0.7:8083"},"tasks":[{"id":0,"state":"RUNNING","worker_id":"172.31.0.7:8083"}],"type":"sink"}

./kafka-console-producer.sh --bootstrap-server localhost:9092 --topic connect_topic --property parse.key=true --property key.separator=:
plums:5

curl -X DELETE http://localhost:8083/connectors/file_sink_connector

###
### LAB Importing Data from a Database with Kafka Connect
###
# Your supermarket company is using Kafka to manage some of its data. 
# They have a PostgreSQL database that contains some important data, 
# but they want to use Kafka to perform stream processing on this data. 
# You have been asked to implement a Connector to load this data from the database into Kafka. 
# Configure this connector so that new records will be automatically loaded into Kafka as they are created in the database.

# Use the following information as you implement a solution:

# The database name on the PostgreSQL server is inventory.
# A database user has been set up which you can use to connect. The credentials are username kafka and password Kafka!.
# Use a topic prefix of postgres- so that the topics created by the connector will be identifiable as coming from the PostgreSQL database.
# The database can be reached at the IP address 10.0.1.102 on port 5432. You can use a JDBC string like this to connect to the database: jdbc:postgresql://10.0.1.102:5432/<database name>.
# The connector class io.confluent.connect.jdbc.JdbcSourceConnector can be used to pull data from databases using JDBC.
# Here is an example of a connector configuration for a JDBC Source Connector:

# "connector.class": "io.confluent.connect.jdbc.JdbcSourceConnector",
# "connection.url": "jdbc:postgresql://10.0.1.102:5432/<database name>",
# "connection.user": "<database user>",
# "connection.password": "<database password>",
# "topic.prefix": "postgres-",
# "mode":"timestamp",
# "timestamp.column.name": "update_ts"

# Once you have set up the connector, log in to the database server and insert a new record for a purchase of plums into the purchases table within the inventory database. Afterward, verify that the new record is automatically ingested into the Kafka topic by the connector. You can insert a new record like so:

# sudo -i -u postgres

# psql

# \c inventory;

# insert into purchases (product, quantity, purchase_time, update_ts) VALUES ('plums', 8, current_timestamp, current_timestamp);
# You can check your topic like so verify the data that is being ingested:

# kafka-console-consumer --bootstrap-server localhost:9092 --topic postgres-purchases --from-beginning
# After inserting the new record in the database, it should automatically appear in the topic.

# If you get stuck, feel free to check out the solution video, or the detailed instructions under each objective. Good luck!

curl -X POST http://localhost:8083/connectors \
  -H 'Accept: */*' \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "inventory_source_connector",
    "config": {
      "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
      "tasks.max": "1",
      "plugin.name": "pgoutput",
      "publication.name": "cdc_publication",
      "slot.name": "inventory",
      "database.hostname": "postgres",
      "database.port": "5432",
      "database.user": "master",
      "database.password": "password",
      "database.dbname": "main",
      "database.server.name": "inv",
      "schema.include": "ods",
      "table.include.list": "ods.purchases",
      "topic.prefix": "postgres.",
      "key.converter": "org.apache.kafka.connect.json.JsonConverter",
      "value.converter": "org.apache.kafka.connect.json.JsonConverter"
    }
  }'
# {"name":"inventory_source_connector","config":{"connector.class":"io.debezium.connector.postgresql.PostgresConnector","tasks.max":"1","plugin.name":"pgoutput","publication.name":"cdc_publication","slot.name":"inventory","database.hostname":"postgres","database.port":"5432","database.user":"master","database.password":"password","database.dbname":"main","database.server.name":"inv","schema.include":"ods","table.include.list":"ods.purchases","topic.prefix":"postgres-","key.converter":"org.apache.kafka.connect.json.JsonConverter","value.converter":"org.apache.kafka.connect.json.JsonConverter","name":"inventory_source_connector"},"tasks":[],"type":"source"}

curl http://localhost:8083/connectors/inventory_source_connector

curl http://localhost:8083/connectors/inventory_source_connector/status

####
#### chapter 11
####
Apache Kafka Security (SSL SASL Kerberos ACL)
- https://www.youtube.com/playlist?list=PLt1SIbA8guusMatdciotF-WyG4IMBT1EG
Encryption (SSL)
Authentication (SSL & SASL)
Authorisation (ACL)

#### TLS Encryption
TLS (Transport Layer Security) Encryption
TLS prevents man-in-the-middle (MITM) attacks, plus ensures that communication between clients and Kafka servers is encrypted.
If you plan to have external clients (eg producers and consumers) connect to Kafka, it may be a good idea to confirm that they use TLS to do so.

To set up TLS, we will need to:
* create a certificate authority
* create signed certificates for our Kafka brokers
* configure brokers to enable TLS and use the certificates
* configure a client to connect securely and trust the certificates

* country (countryName, C)
* state or province name (stateOrProvinceName, ST)
* locality (locality, L)
* organization (organizationName, O)
* organizational unit (organizationalUnitName, OU)
* common name (commonName, CN)

cd security
bash kafka-generate-ssl-automatic.sh
# security
# ├── config
# │   └── client-ssl.properties
# ├── kafka-generate-ssl-automatic.sh
# ├── kafka-hosts.txt
# ├── keystore
# │   └── kafka.server.keystore.jks
# └── truststore
#     ├── ca-key
#     └── kafka.truststore.jks

## PLAINTEXT at 9092 and SSL at 9093
## - KAFKA_CFG_SSL_CLIENT_AUTH=none
docker-compose -f compose-kafka-tls.yml up -d

docker run --rm -it --network kafka-network \
  -v $PWD/security/keystore/kafka.server.keystore.jks:/bitnami/kafka/config/certs/kafka.keystore.jks \
  -v $PWD/security/truststore/kafka.truststore.jks:/bitnami/kafka/config/certs/kafka.truststore.jks \
  -v $PWD/security/config/client-ssl.properties:/bitnami/kafka/config/client-ssl.properties \
  bitnami/kafka:3.3 bash

./kafka-topics.sh --bootstrap-server kafka:9092 --create \
  --topic tls-test --partitions 1 --replication-factor 1

./kafka-console-producer.sh --bootstrap-server kafka:9092 --topic tls-test

./kafka-console-consumer.sh --bootstrap-server kafka:9092 \
  --topic tls-test --from-beginning

./kafka-console-consumer.sh --bootstrap-server kafka:9093 \
  --topic tls-test --from-beginning \
  --consumer.config /bitnami/kafka/config/client-ssl.properties

#### Client Authentication
## PLAINTEXT at 9092 and SSL at 9093
## - KAFKA_CFG_SSL_CLIENT_AUTH=required
docker run --rm -it --network kafka-network \
  -v $PWD/security/keystore/kafka.server.keystore.jks:/bitnami/kafka/config/certs/kafka.keystore.jks \
  -v $PWD/security/truststore/kafka.truststore.jks:/bitnami/kafka/config/certs/kafka.truststore.jks \
  -v $PWD/security/config/client-ssl.properties:/bitnami/kafka/config/client-ssl.properties \
  -v $PWD/security/config/client-mutual-tls.properties:/bitnami/kafka/config/client-mutual-tls.properties \
  bitnami/kafka:3.3 bash

./kafka-topics.sh --bootstrap-server kafka:9092 --create \
  --topic tls-test --partitions 1 --replication-factor 1

./kafka-console-producer.sh --bootstrap-server kafka:9092 --topic tls-test

./kafka-console-consumer.sh --bootstrap-server kafka:9092 \
  --topic tls-test --from-beginning

./kafka-console-consumer.sh --bootstrap-server kafka:9093 \
  --topic tls-test --from-beginning \
  --consumer.config /bitnami/kafka/config/client-ssl.properties
# org.apache.kafka.common.errors.SslAuthenticationException: Failed to process post-handshake messages
# Caused by: javax.net.ssl.SSLHandshakeException: Received fatal alert: bad_certificate

./kafka-console-consumer.sh --bootstrap-server kafka:9093 \
  --topic tls-test --from-beginning \
  --consumer.config /bitnami/kafka/config/client-mutual-tls.properties

###
### LAB Using Client Authentication with Kafka
###
# Your supermarket company is using Kafka as part of its backend data infrastructure. 
# The cluster has already been secured with TLS on a secure port, 
# but currently, any client using that secure port has full access to everything in the cluster.

# You have been asked to implement client authentication using client certificates. 
# The purpose of this task is so that only clients with client certificates 
#   signed by the cluster's certificate authority can use the secure port.

# To complete this task, you will need the following information:

# The certificate authority files you need in order to sign the client certificate 
#   (ca-cert and ca-key) can be found in /home/cloud_user/certs.

# The password for the ca-key is AllTheKeys.

# There is a client configuration file located at /home/cloud_user/client-ssl.properties.

# There is a topic called inventory_purchases with a few test records. You can consume from this topic in order to test your configuration like so:

# kafka-console-consumer --bootstrap-server zoo1:9093 --topic inventory_purchases \
#   --from-beginning --consumer.config client-ssl.properties
# If you get stuck, feel free to check out the solution video, or the detailed instructions under each objective. Good luck!

#######
# mkdir -p security/certs && cd security/certs

# openssl req -new -x509 -keyout ca-key -out ca-cert -days 365 \
#   -subj "/C=US/ST=Texas/L=Keller/O=Linux Academy/OU=Content/CN=CCDAK"

# keytool -keystore client.keystore.jks -alias kafkauser -validity 365 -genkey \
#   -keyalg RSA -dname "CN=kafkauser, OU=Unknown, O=Unknown, L=Unknown, ST=Unknown, C=Unknown"

# keytool -keystore client.keystore.jks -alias kafkauser -certreq -file client-cert-file

# openssl x509 -req -CA ca-cert -CAkey ca-key -in client-cert-file -out client-cert-signed -days 365 -CAcreateserial

# keytool -keystore client.keystore.jks -alias CARoot -import -file ca-cert

# keytool -keystore client.keystore.jks -alias kafkauser -import -file client-cert-signed

# Generate Your Client Certificate Files
# Generate a client certificate. Choose a password for the client keystore when prompted:
# cd ~/certs/

# keytool -keystore client.keystore.jks -alias kafkauser -validity 365 -genkey -keyalg RSA -dname "CN=kafkauser, OU=Unknown, O=Unknown, L=Unknown, ST=Unknown, C=Unknown"
# When prompted, enter the keystore password that was set.
# When prompted, re-enter the keystore password.
# When prompted with RETURN if same as keystore password, just hit enter again to make it the same password as the keystore.
# Sign the key:
# keytool -keystore client.keystore.jks -alias kafkauser -certreq -file client-cert-file
# When prompted, enter the keystore password.

# Sign the certificate:

# openssl x509 -req -CA ca-cert -CAkey ca-key -in client-cert-file -out client-cert-signed -days 365 -CAcreateserial

# 1. When prompted for the `ca-key` passphrase, use  `AllTheKeys`.
# 1. Import the public certificate:

# keytool -keystore client.keystore.jks -alias CARoot -import -file ca-cert

# 1. When prompted, enter the `keystore password`.
# 1. Type `yes` to accept the certificate.
# 1. Import the signed certificate:

# keytool -keystore client.keystore.jks -alias kafkauser -import -file client-cert-signed

# 1. When prompted, enter the `keystore password`.
# 1. Move the client keystore into an appropriate location:

# sudo cp client.keystore.jks /var/private/ssl/

# 1. When prompted, enter the `cloud_user` password.
# 1. Ensure that the file is owned by `root` with:

# sudo chown root:root /var/private/ssl/client.keystore.jks


# ### Enable Client Authentication for the Broker

# 1. Set client authentication to `required` in `server.properties`:

# sudo vi /etc/kafka/server.properties


# 1. Locate the line that begins with `ssl.client.auth` and change it:

# ssl.client.auth=required

# 1. Save the changes to the file.
# 1. Restart Kafka and then verify that everything is working:

# sudo systemctl restart confluent-kafka

# sudo systemctl status confluent-kafka


# ### Add Client Authentication Settings to Your Client Config File

# 1. Edit `client-ssl.properties`:

# cd ~/

# vi client-ssl.properties


# 1. Add the following lines:

# ssl.keystore.location=/var/private/ssl/client.keystore.jks ssl.keystore.password=<your client keystore password> ssl.key.password=<your client key password>


# 1. Create a console consumer using client authentication to make verify that everything is working:

# kafka-console-consumer --bootstrap-server zoo1:9093 --topic inventory_purchases --from-beginning --consumer.config client-ssl.properties

########

docker run --rm -it --network kafka-network \
  -v $PWD/security/certs/client.keystore.jks:/bitnami/kafka/config/certs/client.keystore.jks \
  -v $PWD/security/truststore/kafka.truststore.jks:/bitnami/kafka/config/certs/kafka.truststore.jks \
  -v $PWD/security/config/client-mutual-tls.properties:/bitnami/kafka/config/client-mutual-tls.properties \
  bitnami/kafka:3.3 bash

./kafka-topics.sh --bootstrap-server kafka:9092 --create \
  --topic tls-test --partitions 1 --replication-factor 1

./kafka-console-producer.sh --bootstrap-server kafka:9092 --topic tls-test

./kafka-console-consumer.sh --bootstrap-server kafka:9092 \
  --topic tls-test --from-beginning

./kafka-console-consumer.sh --bootstrap-server kafka:9093 \
  --topic tls-test --from-beginning \
  --consumer.config /bitnami/kafka/config/client-mutual-tls.properties

###
### LAB Kafka Authorization Using ACLs
###
# Your supermarket company is using client authentication and ACLs in order to manage access to a Kafka cluster. 
# They have ACLs configured for some existing topics but due to new requirements, some changes need to be made 
#   in order to allow access for a new client user called kafkauser. Note that allow.everyone.if.no.acl.found is set to true for this cluster.

# Implement the following authorization changes to the cluster:

# Provide kafkauser with read and write access to the inventory_purchases topic
# Remove all existing ACLs for the member_signups topic to allow access to all users, including kafkauser
# There is a client configuration file on the server located at /home/cloud_user/client-ssl.properties. This configuration will allow you to authenticate as kafkauser.

# If you get stuck, feel free to check out the solution video, or the detailed instructions under each objective. Good luck!

# Create the ACL.
# kafka-acls --authorizer-properties zookeeper.connect=localhost:2181 --add --allow-principal User:kafkauser --operation read --operation write --topic inventory_purchases
# Verify that the read access works by consuming from the topic.
# kafka-console-consumer --bootstrap-server zoo1:9093 --topic inventory_purchases --from-beginning --consumer.config client-ssl.properties
# Data from that topic should be displayed. Pressing Ctrl+C will stop the command so that we can continue.

# Verify that the write access works by writing data to the topic.
# kafka-console-producer --broker-list zoo1:9093 --topic inventory_purchases --producer.config client-ssl.properties
# After running this command, provide some sample data such as "test data" or "another test" and press Enter. If no errors are displayed, the write was successful. Press Ctrl+C to stop the command to continue.

# Remove All Existing ACLs for the member_signups Topic
# List the ACLs for the topic.
# kafka-acls --authorizer-properties zookeeper.connect=localhost:2181 --topic member_signups --list
# Remove the existing ACL for the topic.
# kafka-acls --authorizer-properties zookeeper.connect=localhost:2181 --topic member_signups --remove
# At the prompt, enter y to confirm the removal.

# Verify that you can read from the topic as kafkauser.
# kafka-console-consumer --bootstrap-server zoo1:9093 --topic member_signups --from-beginning --consumer.config client-ssl.properties
# Data from the topic should be displayed.

####
#### chapter 12
####

#### LAB Writing Tests for a Kafka Producer
# Your supermarket company is using Kafka to manage some of their back-end data infrastructure. 
# They have created a membership program for customers, and a Kafka producer publishes a message to Kafka every time a new member signs up for the program.

# Unfortunately, the developer who wrote the producer code had to go on sick leave before they could write unit tests for the code. 
# Your task is to create some unit tests for the producer class.

# There is a project in GitHub that contains the code. Clone this project to the Dev server. 
# The producer class is located at src/main/java/com/linuxacademy/ccdak/producer/MemberSignupsProducer.java. You can find a test class at src/test/java/com/linuxacademy/ccdak/producer/MemberSignupsProducerTest.java. Edit the test class and implement your unit tests there. There are already test methods and some test fixtures set up in the class.

# Luckily, the developer left behind some notes on the unit tests that need to be created.

# testHandleMemberSignup_sent_data — Call the handleMemberSignup method and test that the correct data is sent by the producer (both key and value).
# testHandleMemberSignup_partitioning — The producer implements custom partitioning. Records where the value starts with the letters A–M are sent to partition 0, and the rest are sent to partition 1. Call handleMemberSignup twice — once with a value that starts with A–M and once with a value that starts with N–Z. Test that the partitions were set appropriately for these records.
# testHandleMemberSignup_output — The producer implements a callback that prints the key and value of the record to System.out once the record is acknowledged. Test that the correct data is printed to System.out by the callback. A test fixture has already been set up that will allow you access data printed to System.out during the test like so: systemOutContent.toString().
# testHandleMemberSignup_error — The producer implements a callback that prints the error message to System.err when there is an error. Make the producer return an error and test that the correct data is printed to System.err by the callback. A test fixture has already been set up that will allow you access data printed to System.err during the test like so: systemErrContent.toString().

#### LAB Writing Tests for a Kafka Consumer
# Your supermarket company has a consumer that consumes messages that are created when customers sign up for a membership program. 
# This consumer simply logs the messages and their metadata to the console.

# The company is reviewing the codebase for compliance with good practices, and this consumer has no unit tests. 
# Your task is to write some unit tests for the consumer.

# There is a project in GitHub that contains the code. Clone this project to the Dev server. 
# The consumer class is located at src/main/java/com/linuxacademy/ccdak/consumer/MemberSignupsConsumer.java. You can find a test class at src/test/java/com/linuxacademy/ccdak/consumer/MemberSignupsConsumerTest.java. Edit the test class and implement your unit tests there. There are already test methods and some test fixtures set up in the class.

# Note the test class contains a test fixture called systemOutContent. You can use this to access data written to System.out during the test like so:

# systemOutContent.toString()
# Here are some notes on the tests that need to be created:

# testHandleRecords_output — This test should simply verify the output. Call the handleRecords and pass in a record. Test that the data is written to System.out in the expected format.
# testHandleRecords_none — Test that handleRecords works as expected when the collection of records is empty.
# testHandleRecords_multiple — Test that handleRecords works as expected when the collection of records contains more than one record.

#### LAB Writing Tests for a Kafka Streams Application
# Your supermarket company has a Kafka Streams application that processes messages that are created when customers sign up for a membership program. 
# The application reads these incoming messages and produces data to an output topic that is used to send customers an email with information about their new membership account. 
# This output topic is keyed to the member ID, and the record values are the customer's first name, formatted properly for the mailing.

# The company is reviewing the codebase for compliance with good practices, and this Streams application has no unit tests. 
# Your task is to write some unit tests for the application.

# There is a project in GitHub that contains the code. Clone this project to the Dev server. 
# The consumer class is located at src/main/java/com/linuxacademy/ccdak/streams/MemberSignupsStream.java. You can find a test class at src/test/java/com/linuxacademy/ccdak/streams/MemberSignupsStreamTest.java. Edit the test class and implement your unit tests there. There are already test methods and some test fixtures set up in the class.

# Here are some notes on the features of the application and the tests that need to be created:

# test_first_name — The stream takes records which usually have customer names in the form LastName, FirstName. The stream parses the value in order to extract only the first name for the mailing. Test this functionality by producing a record with a value in the LastName, FirstName format and verifying that the output record has only the first name as its value.
# test_unknown_name_filter — Some legacy systems are still producing records to the input topic with a value of UNKNOWN when the customer name is unknown. For now, we won't send these customers an email, so the stream filters these records out. Produce a record with a value of UNKNOWN and verify that there is no corresponding output record.
# test_empty_name_filter — There are also some input systems that produce records to the input topic with an empty string as the value when the customer name is unknown. The streams application also filters out these records. Produce a record with an empty value and verify that there is no corresponding output record.

####
#### chapter 13
####

#### LAB Tuning a Kafka Producer
# Your supermarket company has a producer that publishes messages to a topic called member_signups. 
# After running this producer for a while in production, three issues have arisen that require some adjustments to the producer configuration. 
# You have been asked to make some changes to the producer configuration code to address these issues.

# The source code can be found on GitHub. Clone this project to the broker. 
# You should be able to implement all the necessary changes in the file src/main/java/com/linuxacademy/ccdak/producer/MemberSignupsProducer.java inside the project.

# Make configuration changes to address the following issues:

# Recently, a Kafka broker failed and had to be restarted. Unfortunately, that broker was the leader for a partition of the member_signups topic at the time, 
# and a few records had been committed by the leader but had not yet been written to the replicas. 
# A small number of records were lost when the leader failed. Change the configuration so that this does not happen again.
# The producer is configured to retry the process of sending a record when it fails due to a transient error. 
# However, in a few instances this has caused records to be written to the topic log in a different order than the order they were sent by the producer, 
# because a record was retried while another record was sent ahead of it. 
# A few downstream consumers depend on certain ordering guarantees for this data. 
# Ensure that retries by the producer do not result in out-of-order records.
# This producer sometimes experiences high throughput that could benefit from a greater degree of message batching. Increase the batch size to 64 KB (65536 bytes).

#### LAB Tuning a Kafka Consumer
# Your supermarket company has a consumer that logs data from the member_signups topic to System.out. 
# This consumer acts as a utility to log the data for later auditing. 
# However, there is a series of issues with this consumer that can be addressed through some minor alterations to its configuration. 
# Examine the list of issues below and resolve them by implementing the necessary configuration changes in the consumer code.

# You can find the consumer code on GitHub. Clone this project to the broker server. 
# You can implement your configuration changes in the consumer class at src/main/java/com/linuxacademy/ccdak/consumer/MemberSignupsConsumer.java inside the project.

# Make configuration changes to address the following issues:

# This consumer does not have a high need for real-time data since it is merely a logging utility that provides data for later analysis. 
# Increase the minimum fetch size to 1 K (1024 bytes) to allow the consumer to fetch more data in a single request.

# Changes in consumer status (such as consumers joining or leaving the group) are not being detected quickly enough. 
# Configure the consumer to send a heartbeat every two seconds (2000ms).

# Last week, someone tried to run this consumer against a new cluster. The consumer failed with the following error message:

# Exception in thread "main" org.apache.kafka.clients.consumer.NoOffsetForPartitionException: Undefined offset with no reset policy for partitions: [member_signups-0]
# Ensure the consumer has an offset reset policy that will allow the consumer to read from the beginning of the log when reading from a partition for the first time.

####
#### chapter 14
####
./kafka-topics.sh --bootstrap-server localhost:9092 --create \
  --topic ksql-test --partitions 1 --replication-factor 1

./kafka-console-producer.sh --bootstrap-server localhost:9092 \
  --topic ksql-test --property parse.key=true --property key.separator=:
5:5,sarah,2
7:7,andy,1
5:5,sarah,3

./kafka-console-consumer.sh --bootstrap-server localhost:9092 \
  --topic ksql-test --from-beginning --property print.key=true

docker exec -it ksqldb-cli ksql http://ksqldb-server:8088

--//
SET 'auto.offset.reset' = 'earliest';
SHOW TOPICS;
PRINT 'ksql-test';
CREATE STREAM ksql_test_stream (
  employee_id INTEGER, 
  name VARCHAR,
  vacation_days INTEGER
) WITH (
  kafka_topic='ksql-test', value_format='DELIMITED'
);
SELECT * FROM ksql_test_stream;
# +----------------------------------------------------------+----------------------------------------------------------+----------------------------------------------------------+
# |EMPLOYEE_ID                                               |NAME                                                      |VACATION_DAYS                                             |
# +----------------------------------------------------------+----------------------------------------------------------+----------------------------------------------------------+
# |5                                                         |sarah                                                     |2                                                         |
# |7                                                         |andy                                                      |1                                                         |
# |5                                                         |sarah                                                     |3                                                         |
# Query Completed
# Query terminated
SELECT SUM(vacation_days) FROM ksql_test_stream GROUP BY employee_id EMIT CHANGES;
# +----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
# |KSQL_COL_0                                                                                                                                                                        |
# +----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
# |2                                                                                                                                                                                 |
# |1                                                                                                                                                                                 |
# |5                                                                                                                                                                                 |

CREATE TABLE ksql_test_table (
  employee_id INTEGER PRIMARY KEY, 
  name VARCHAR,
  vacation_days INTEGER
) WITH (
  kafka_topic='ksql-test', value_format='DELIMITED'
);
# Tables have PRIMARY KEYs, which are unique and NON NULL.
# Streams have KEYs, which have no uniqueness or NON NULL constraints.

SELECT * FROM ksql_test_table;
# The `KSQL_TEST_TABLE` table isn't queryable. To derive a queryable table, you can do 'CREATE TABLE QUERYABLE_KSQL_TEST_TABLE AS SELECT * FROM KSQL_TEST_TABLE'. See https://cnfl.io/queries for more info.
# Add EMIT CHANGES if you intended to issue a push query.
# Statement: SELECT * FROM ksql_test_table;

#### LAB Working with KSQL Streams
# Your supermarket company has a customer membership program, and they are using Kafka to manage some of the back-end data related to this program. 
# A topic called member_signups contains records that are published when a new customer signs up for the program. 
# Each record contains some data indicating whether or not the customer has agreed to receive email notifications.

# The email notification system reads from a Kafka topic, so a topic called member_signups_email needs to be created that contains the new member data, 
# but only for members who have agreed to receive notifications. 
# The company would like to have this data automatically processed in real-time so that consumer applications can appropriately respond when a customer signs up. 
# Luckily, this use case can be accomplished using KSQL persistent streaming queries, so you do not need to write a Kafka Streams application.

# The data in member_signups is formatted with the key as the member ID. 
# The value is a comma-delimited list of fields in the form <last name>,<first name>,<email notifications true/false>.

# Create a stream that pulls the data from member_signups, and then create a persistent streaming query to filter out records where the email notification value is false 
# and output the result to the member_signups_email topic.
./kafka-topics.sh --bootstrap-server localhost:9092 --create \
  --topic member_signups --partitions 1 --replication-factor 1

./kafka-console-producer.sh --bootstrap-server localhost:9092 \
  --topic member_signups --property parse.key=true --property key.separator=:
1:doe,john,true
2:doe,jane,false
3:smith,john,true

./kafka-console-consumer.sh --bootstrap-server localhost:9092 \
  --topic member_signups --from-beginning --property print.key=true

docker exec -it ksqldb-cli ksql http://ksqldb-server:8088

SET 'auto.offset.reset' = 'earliest';
SHOW TOPICS;
PRINT 'member_signups';
# Key format: JSON or KAFKA_STRING
# Value format: KAFKA_STRING
# rowtime: 2023/03/27 17:22:00.772 Z, key: 1, value: doe,john,true, partition: 0
# rowtime: 2023/03/27 17:22:05.008 Z, key: 2, value: doe,jane,false, partition: 0
# rowtime: 2023/03/27 17:22:09.032 Z, key: 3, value: smith,john,true, partition: 0
# Topic printing ceased
CREATE STREAM member_signups (
  last_name VARCHAR, 
  first_name VARCHAR,
  email_notification BOOLEAN
) WITH (
  kafka_topic='member_signups', value_format='DELIMITED'
);
SELECT * FROM member_signups;

CREATE STREAM member_signups_email AS
  SELECT * FROM member_signups WHERE email_notification = true;
SELECT * FROM member_signups_email;

#### LAB Joining Datasets with KSQL
# Your supermarket company has a customer membership program. Some of the data for this program is managed using Kafka. 

# There are currently two relevant topics:
# * member_signups — Key: member ID, value: Customer name.
# * member_contact — Key: member ID, value: Customer email address.

# The company would like to send an email to new members when they join. 
# This email needs to contain the customer's name, and it needs to be sent to the customer's email address, 
#   but these pieces of data are currently in two different topics. 

# Using KSQL, create a persistent streaming query to join the customer names and email addresses, 
#   and stream the result to an output topic called MEMBER_EMAIL_LIST.

./kafka-topics.sh --bootstrap-server localhost:9092 --delete --topic member_signups
./kafka-topics.sh --bootstrap-server localhost:9092 --create \
  --topic member_signups --partitions 1 --replication-factor 1
./kafka-console-producer.sh --bootstrap-server localhost:9092 \
  --topic member_signups --property parse.key=true --property key.separator=:
1:john doe
2:jane doe
3:john smith
./kafka-console-consumer.sh --bootstrap-server localhost:9092 \
  --topic member_signups --from-beginning --property print.key=true

./kafka-topics.sh --bootstrap-server localhost:9092 --create \
  --topic member_contact --partitions 1 --replication-factor 1
./kafka-console-producer.sh --bootstrap-server localhost:9092 \
  --topic member_contact --property parse.key=true --property key.separator=:
1:john@doe
2:jane@doe
3:john@smith
./kafka-console-consumer.sh --bootstrap-server localhost:9092 \
  --topic member_contact --from-beginning --property print.key=true

SET 'auto.offset.reset' = 'earliest';
SHOW TOPICS;
PRINT 'member_signups';
PRINT 'member_contact';
DROP STREAM IF EXISTS member_signups_email;
DROP STREAM IF EXISTS member_signups;
CREATE STREAM member_signups (
  rowkey VARCHAR KEY,
  name VARCHAR
) WITH (
  kafka_topic='member_signups', value_format='DELIMITED'
);
PRINT 'member_signups' FROM BEGINNING;
SELECT * FROM member_signups;

DROP STREAM IF EXISTS member_contact;
CREATE STREAM member_contact (
  rowkey VARCHAR KEY,
  email VARCHAR
) WITH (
  kafka_topic='member_contact', value_format='DELIMITED'
);
PRINT 'member_contact' FROM BEGINNING;
SELECT * FROM member_contact;

CREATE STREAM member_email_list AS
  SELECT member_signups.rowkey, member_signups.name, member_contact.email
  FROM member_signups
  INNER JOIN member_contact WITHIN 365 DAYS ON member_signups.rowkey = member_contact.rowkey
  EMIT CHANGES;
# WARNING: DEPRECATION NOTICE: Stream-stream joins statements without a GRACE PERIOD will not be accepted in a future ksqlDB version.
# Please use the GRACE PERIOD clause as specified in https://docs.ksqldb.io/en/latest/developer-guide/ksqldb-reference/select-push-query/
PRINT 'MEMBER_EMAIL_LIST' FROM BEGINNING;
SELECT * FROM member_email_list;
