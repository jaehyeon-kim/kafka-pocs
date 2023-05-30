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
