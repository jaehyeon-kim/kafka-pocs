#!/usr/bin/env bash
SCRIPT_DIR="$(cd $(dirname "$0"); pwd)"

SRC_PATH=${SCRIPT_DIR}/infra/connectors
rm -rf ${SRC_PATH} && mkdir ${SRC_PATH}

## MSK Data Generator Souce Connector
echo "downloading msk data generator..."
DOWNLOAD_URL=https://github.com/awslabs/amazon-msk-data-generator/releases/download/v0.4.0/msk-data-generator-0.4-jar-with-dependencies.jar

curl -L -o ${SRC_PATH}/msk-data-generator.jar ${DOWNLOAD_URL}

# Build kinesis kafka connector
echo "build kinesis kafka connector..."
git clone https://github.com/awslabs/kinesis-kafka-connector.git ${SRC_PATH}/kinesis-kafka-connector \
  && cd ${SRC_PATH}/kinesis-kafka-connector \
  && mvn clean install -DskipTests \
  && mv ${SRC_PATH}/kinesis-kafka-connector/target/kinesis-kafka-connector.jar ${SRC_PATH} \
  && rm -rf ${SRC_PATH}/kinesis-kafka-connector

## Download camel redshift sink connector
echo "download camel redshift sink connector..."
DOWNLOAD_URL=https://repo.maven.apache.org/maven2/org/apache/camel/kafkaconnector/camel-aws-redshift-sink-kafka-connector/3.18.2/camel-aws-redshift-sink-kafka-connector-3.18.2-package.tar.gz

curl -o ${SRC_PATH}/camel-aws-redshift-sink-kafka-connector.tar.gz ${DOWNLOAD_URL} \
  && tar -xvzf ${SRC_PATH}/camel-aws-redshift-sink-kafka-connector.tar.gz -C ${SRC_PATH} \
  && cd ${SRC_PATH}/camel-aws-redshift-sink-kafka-connector \
  && zip -r camel-aws-redshift-sink-kafka-connector.zip . \
  && mv camel-aws-redshift-sink-kafka-connector.zip ${SRC_PATH} \
  && rm ${SRC_PATH}/camel-aws-redshift-sink-kafka-connector.tar.gz
