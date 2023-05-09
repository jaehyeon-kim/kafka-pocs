#!/usr/bin/env bash
SCRIPT_DIR="$(cd $(dirname "$0"); pwd)"

SRC_PATH=${SCRIPT_DIR}/connectors
rm -rf ${SRC_PATH} && mkdir -p ${SRC_PATH}/msk-datagen

## Confluent S3 Sink Connector
S3_SINK_CONNECTOR_VERSION="10.4.3"
echo "downloading confluent s3 connector..."
DOWNLOAD_URL=https://d1i4a15mxbxib1.cloudfront.net/api/plugins/confluentinc/kafka-connect-s3/versions/10.4.3/confluentinc-kafka-connect-s3-10.4.3.zip

curl ${DOWNLOAD_URL} -o ${SRC_PATH}/confluent.zip \
  && unzip -qq ${SRC_PATH}/confluent.zip -d ${SRC_PATH} \
  && rm ${SRC_PATH}/confluent.zip \
  && mv ${SRC_PATH}/$(ls ${SRC_PATH} | grep confluentinc-kafka-connect-s3) ${SRC_PATH}/confluent-s3

## MSK Data Generator Souce Connector
echo "downloading msk data generator..."
DOWNLOAD_URL="https://github.com/awslabs/amazon-msk-data-generator/releases/download/v0.4.0/msk-data-generator-0.4-jar-with-dependencies.jar"

curl ${DOWNLOAD_URL} -o ${SRC_PATH}/msk-datagen/msk-data-generator.jar
