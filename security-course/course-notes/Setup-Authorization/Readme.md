# Configure Kafka Broker
```
sudo vi ~/kafka/config/server.properties  
```
=> replace content by [this one](./server.properties)

```
sudo systemctl restart kafka  
sudo systemctl status kafka  
```
# Create a topic
```
~/kafka/bin/kafka-topics.sh \
--zookeeper <<KAFKA-SERVER-PUBLIC-DNS>>:2181 \
--create \
--topic acl-test \
--replication-factor 1 --partitions 1
```
# Create ACLs

1.) Allow users _reader_ and _writer_ to consumer from topic _acl-test_
```
~/kafka/bin/kafka-acls.sh \
--authorizer-properties zookeeper.connect=<<KAFKA-SERVER-PUBLIC-DNS>>:2181 --add \
--allow-principal User:reader --allow-principal User:writer \
--operation Read \
--group=* \
--topic acl-test
```
2.) Allow user _writer_ to produce messages into topic _acl-test_
```
~/kafka/bin/kafka-acls.sh \
--authorizer-properties zookeeper.connect=<<KAFKA-SERVER-PUBLIC-DNS>>:2181 --add \
--allow-principal User:writer \
--operation Write \
--topic acl-test
```
3.) Allow ClusterAction for everyone
```
 Principal = User:ANONYMOUS is Allowed Operation = ClusterAction
```

Listing acls
```
~/kafka/bin/kafka-acls.sh \
--authorizer-properties zookeeper.connect=<<KAFKA-SERVER-PUBLIC-DNS>>:2181 \
--list \
--topic acl-test
```
# Test consuming and producing messages
1.) start console-producer as user _writer_
```
export KAFKA_OPTS="-Djava.security.auth.login.config=/tmp/kafka_client_jaas.conf"

kdestroy
kinit -kt /tmp/writer.user.keytab writer

~/kafka/bin/kafka-console-producer.sh \
--broker-list <<KAFKA-SERVER-PUBLIC-DNS>>:9094 \
--topic acl-test \
--producer.config /tmp/kafka_client_kerberos.properties
```
2.) start a console-consumer as user _reader_
```
export KAFKA_OPTS="-Djava.security.auth.login.config=/tmp/kafka_client_jaas.conf"

kdestroy
kinit -kt /tmp/reader.user.keytab reader

~/kafka/bin/kafka-console-consumer.sh \
--bootstrap-server <<KAFKA-SERVER-PUBLIC-DNS>>:9094 \
--topic acl-test \
--consumer.config /tmp/kafka_client_kerberos.properties
```
3.) Remove _Read_ permissions from user _reader_
```
~/kafka/bin/kafka-acls.sh \
--authorizer-properties zookeeper.connect=<<KAFKA-SERVER-PUBLIC-DNS>>:2181 --remove \
--allow-principal User:reader \
--operation Read \
--topic acl-test
```
4.) start the console-consumer again as user _reader_
```
export KAFKA_OPTS="-Djava.security.auth.login.config=/tmp/kafka_client_jaas.conf"

kdestroy
kinit -kt /tmp/reader.user.keytab reader

~/kafka/bin/kafka-console-producer.sh \
--broker-list <<KAFKA-SERVER-PUBLIC-DNS>>:9094 \
--topic acl-test \
--producer.config /tmp/kafka_client_kerberos.properties
```
