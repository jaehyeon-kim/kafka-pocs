https://www.oreilly.com/library/view/building-data-streaming/9781787283985/00f04fe0-e36d-447c-80d1-9d482e321d4e.xhtml
https://tutorialspedia.com/an-overview-of-one-way-ssl-and-two-way-ssl/

https://docs.aws.amazon.com/msk/latest/developerguide/data-protection.html
https://docs.aws.amazon.com/msk/latest/developerguide/kafka_apis_iam.html

https://stackoverflow.com/questions/51630260/connect-to-kafka-running-in-docker#51634499
https://github.com/bitnami/containers/tree/main/bitnami/kafka#accessing-apache-kafka-with-internal-and-external-clients

https://wiki.folio.org/pages/viewpage.action?spaceKey=FOLIJET&title=Enabling+SSL+and+ACL+for+Kafka

https://github.com/bitnami/containers/blob/main/bitnami/kafka/README.md

setup a certificate authority
setup a broker certificate
sign a broker certificate
setup a key store for kafka broker
setup a trust store for kafka client
reboot kafka broker with SSL mode (port 9093)
test setup using a secure ssl producer/consumer

https://docs.confluent.io/platform/current/kafka/authentication_ssl.html
https://docs.confluent.io/platform/current/security/security_tutorial.html#security-tutorial
https://docs.confluent.io/platform/current/security/security_tutorial.html#generating-keys-certs

############# SSL
docker exec -it kafka-1 bash
cd /opt/bitnami/kafka/bin/

./kafka-topics.sh --bootstrap-server kafka-0:9093 \
  --create --topic inventory --partitions 3 --replication-factor 3 \
  --command-config /opt/bitnami/kafka/config/client.properties
# Created topic orders.

./kafka-console-producer.sh --bootstrap-server kafka-0:9093 \
  --topic inventory --producer.config /opt/bitnami/kafka/config/client.properties

product: apples, quantity: 5
product: lemons, quantity: 7

./kafka-console-consumer.sh --bootstrap-server kafka-0:9093 \
  --topic inventory --consumer.config /opt/bitnami/kafka/config/client.properties \
  --from-beginning

############# SASL
docker exec -it kafka-0 bash
cd /opt/bitnami/kafka/bin/

## create sasl user
./kafka-configs.sh --bootstrap-server kafka-1:9093 --describe \
  --entity-type users --command-config /opt/bitnami/kafka/config/command.properties

./kafka-configs.sh --bootstrap-server kafka-1:9093 --alter \
  --add-config 'SCRAM-SHA-256=[iterations=8192,password=password]' \
  --entity-type users --entity-name client \
  --command-config /opt/bitnami/kafka/config/command.properties

## produce/consume messages
./kafka-console-producer.sh --bootstrap-server kafka-1:9094 \
  --topic inventory --producer.config /opt/bitnami/kafka/config/client.properties
product: apples, quantity: 5
product: lemons, quantity: 7

./kafka-console-consumer.sh --bootstrap-server kafka-1:9094 \
  --topic inventory --consumer.config /opt/bitnami/kafka/config/client.properties \
  --from-beginning

############# SASL + Authorization
docker exec -it kafka-0 bash
cd /opt/bitnami/kafka/bin/

## create sasl users
./kafka-configs.sh --bootstrap-server kafka-1:9093 --describe \
  --entity-type users --command-config /opt/bitnami/kafka/config/command.properties

# super user
./kafka-configs.sh --bootstrap-server kafka-1:9093 --alter \
  --add-config 'SCRAM-SHA-256=[iterations=8192,password=password]' \
  --entity-type users --entity-name superuser \
  --command-config /opt/bitnami/kafka/config/command.properties

# client users
for USER in "client" "producer" "consumer"; do
  echo $USER
  ./kafka-configs.sh --bootstrap-server kafka-1:9094 --alter \
    --add-config 'SCRAM-SHA-256=[iterations=8192,password=password]' \
    --entity-type users --entity-name $USER \
    --command-config /opt/bitnami/kafka/config/superuser.properties
done

./kafka-configs.sh --bootstrap-server kafka-1:9094 --describe \
  --entity-type users --command-config /opt/bitnami/kafka/config/superuser.properties

## create ACL rules
./kafka-acls.sh --bootstrap-server kafka-1:9094 --add \
  --allow-principal User:client --operation All --group '*' \
  --topic inventory --command-config /opt/bitnami/kafka/config/superuser.properties

./kafka-acls.sh --bootstrap-server kafka-1:9094 --list \
  --topic inventory --command-config /opt/bitnami/kafka/config/superuser.properties

./kafka-acls.sh --bootstrap-server kafka-1:9094 --add \
  --allow-principal User:producer --producer \
  --topic orders --command-config /opt/bitnami/kafka/config/superuser.properties

./kafka-acls.sh --bootstrap-server kafka-1:9094 --add \
  --allow-principal User:consumer --consumer --group '*' \
  --topic orders --command-config /opt/bitnami/kafka/config/superuser.properties

./kafka-acls.sh --bootstrap-server kafka-1:9094 --list \
  --topic orders --command-config /opt/bitnami/kafka/config/superuser.properties

## create topic
# ./kafka-topics.sh --bootstrap-server kafka-1:9094 --create \
#   --topic inventory --command-config /opt/bitnami/kafka/config/client.properties

## produce/consume messages
./kafka-console-producer.sh --bootstrap-server kafka-1:9094 \
  --topic inventory --producer.config /opt/bitnami/kafka/config/client.properties
product: apples, quantity: 5
product: lemons, quantity: 7

./kafka-console-consumer.sh --bootstrap-server kafka-1:9094 \
  --topic inventory --consumer.config /opt/bitnami/kafka/config/client.properties \
  --from-beginning

#############
ca-key
ca-cert
- will be external, need to request

never distribute
ca-key
kafka.server.keystore.jks

can distribute, import their truststore
ca-cert
cert-sigend

http://maximilianchrist.com/python/databases/2016/08/13/connect-to-apache-kafka-from-python-using-ssl.html
https://dev.to/adityakanekar/connecting-to-kafka-cluster-using-ssl-with-python-k2e
https://github.com/confluentinc/confluent-kafka-python/issues/1350

https://docs.aiven.io/docs/products/kafka/howto/connect-with-python

docker logs consumer >& log.log

https://github.com/bitnami/containers/issues/23077
https://medium.com/@hussein.joe.au/kafka-authentication-using-sasl-scram-740e55da1fbc

docker run --rm -it  confluentinc/cp-kafka:5.0.1 kafka-configs --zookeeper zookeeper-1:22181 --alter --add-config \
'SCRAM-SHA-256=[iterations=4096,password=password]' --entity-type users --entity-name metricsreporter


https://docs.vmware.com/en/VMware-Smart-Assurance/10.1.0/sa-ui-installation-config-guide-10.1.0/GUID-DF659094-60D3-4E1B-8D63-3DE3ED8B0EDF.html
https://github.com/vdesabou/kafka-docker-playground/tree/master/environment/sasl-scram


https://heodolf.tistory.com/16
https://access.redhat.com/documentation/en-us/red_hat_amq/7.2/html/using_amq_streams_on_red_hat_enterprise_linux_rhel/configuring_zookeeper

https://supergloo.com/kafka-tutorials/
https://supergloo.com/kafka-tutorials/kafka-acl/
https://supergloo.com/kafka-tutorials/kafka-authentication/

https://devidea.tistory.com/102
https://developer.ibm.com/tutorials/kafka-authn-authz/
https://yang1s.tistory.com/17

https://docs.confluent.io/platform/current/kafka/authorization.html