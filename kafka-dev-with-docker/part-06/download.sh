#!/usr/bin/env bash
SCRIPT_DIR="$(cd $(dirname "$0"); pwd)"

SRC_PATH=${SCRIPT_DIR}/connectors
rm -rf ${SRC_PATH} && mkdir -p ${SRC_PATH}/msk-datagen

## Confluent S3 Sink Connector
echo "downloading confluent s3 connector..."
DOWNLOAD_URL=https://d1i4a15mxbxib1.cloudfront.net/api/plugins/confluentinc/kafka-connect-s3/versions/10.4.3/confluentinc-kafka-connect-s3-10.4.3.zip

curl -o ${SRC_PATH}/confluent.zip ${DOWNLOAD_URL} \
  && unzip -qq ${SRC_PATH}/confluent.zip -d ${SRC_PATH} \
  && rm ${SRC_PATH}/confluent.zip \
  && mv ${SRC_PATH}/$(ls ${SRC_PATH} | grep confluentinc-kafka-connect-s3) ${SRC_PATH}/confluent-s3

## MSK Data Generator Souce Connector
echo "downloading msk data generator..."
DOWNLOAD_URL=https://github.com/awslabs/amazon-msk-data-generator/releases/download/v0.4.0/msk-data-generator-0.4-jar-with-dependencies.jar

curl -L -o ${SRC_PATH}/msk-datagen/msk-data-generator.jar ${DOWNLOAD_URL}

## Kafka UI Glue SERDE
echo "downloading kafka ui glue serde..."
DOWNLOAD_URL=https://github.com/provectus/kafkaui-glue-sr-serde/releases/download/v1.0.3/kafkaui-glue-serde-v1.0.3-jar-with-dependencies.jar

curl -L -o ${SCRIPT_DIR}/kafkaui-glue-serde-v1.0.3-jar-with-dependencies.jar ${DOWNLOAD_URL}