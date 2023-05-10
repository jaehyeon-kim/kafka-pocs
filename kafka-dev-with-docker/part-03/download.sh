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
echo "building msk data generator..."
git clone --depth 1 -b v0.4.0 https://github.com/awslabs/amazon-msk-data-generator.git ${SRC_PATH}/amazon-msk-data-generator \
  && cd ${SRC_PATH}/amazon-msk-data-generator \
  && mvn clean install -DskipTests \
  && mv ${SRC_PATH}/amazon-msk-data-generator/target/msk-data-generator-0.4-jar-with-dependencies.jar ${SRC_PATH}/msk-datagen
