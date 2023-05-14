https://www.oreilly.com/library/view/building-data-streaming/9781787283985/00f04fe0-e36d-447c-80d1-9d482e321d4e.xhtml
https://tutorialspedia.com/an-overview-of-one-way-ssl-and-two-way-ssl/

https://docs.aws.amazon.com/msk/latest/developerguide/data-protection.html
https://docs.aws.amazon.com/msk/latest/developerguide/kafka_apis_iam.html

https://stackoverflow.com/questions/51630260/connect-to-kafka-running-in-docker#51634499
https://github.com/bitnami/containers/tree/main/bitnami/kafka#accessing-apache-kafka-with-internal-and-external-clients

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