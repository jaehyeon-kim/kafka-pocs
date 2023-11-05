FROM bitnami/kafka:2.8.1

COPY ./connectors/confluent-s3/lib /opt/connectors/confluent-s3
COPY ./connectors/msk-datagen /opt/connectors/msk-datagen

CMD [ "/opt/bitnami/kafka/bin/connect-distributed.sh", "/opt/bitnami/kafka/config/connect-distributed.properties" ]