# How to prepare Kafka console clients to use in kerberized env  

## Create jaas file including how to use Kerberos ticket  
use [kafka_client_jaas.conf](./kafka_client_jaas.conf) and save it under /tmp/kafka_client_jaas.conf

## Create properties file including Kerberos details
use [kafka_client_kerberos.properties](./kafka_client_kerberos.properties) and save it under /tmp/kafka_client_kerberos.properties

## Start console-producer/-consumer
```
export KAFKA_OPTS="-Djava.security.auth.login.config=/tmp/kafka_client_jaas.conf"

kinit -kt /tmp/admin.user.keytab admin

~/kafka/bin/kafka-console-producer.sh --broker-list <<KAFKA-SERVER-PUBLIC-DNS>>:9094 --topic kafka-security-topic --producer.config /tmp/kafka_client_kerberos.properties
```
2nd terminal:
```
export KAFKA_OPTS="-Djava.security.auth.login.config=/tmp/kafka_client_jaas.conf"

kinit -kt /tmp/reader.user.keytab reader

~/kafka/bin/kafka-console-consumer.sh --bootstrap-server <<KAFKA-SERVER-PUBLIC-DNS>>:9094 --topic kafka-security-topic --consumer.config /tmp/kafka_client_kerberos.properties
```
