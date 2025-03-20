#!/usr/bin/env bash
SCRIPT_DIR="$(cd $(dirname "$0"); pwd)"

SRC_PATH=${SCRIPT_DIR}/connect

rm -rf ${SRC_PATH} && mkdir -p ${SRC_PATH}

## Confluent DataGen Connector
echo "download confluent datagen connector..."
DOWNLOAD_URL=https://hub-downloads.confluent.io/api/plugins/confluentinc/kafka-connect-datagen/versions/0.6.6/confluentinc-kafka-connect-datagen-0.6.6.zip

curl -o ${SRC_PATH}/datagen.zip ${DOWNLOAD_URL} \
  && unzip -qq ${SRC_PATH}/datagen.zip -d ${SRC_PATH} \
  && rm ${SRC_PATH}/datagen.zip \
  && mv ${SRC_PATH}/$(ls ${SRC_PATH} | grep confluentinc-kafka-connect-datagen) ${SRC_PATH}/datagen
