#!/usr/bin/env bash
SCRIPT_DIR="$(cd $(dirname "$0"); pwd)"

SRC_PATH=${SCRIPT_DIR}/connectors
rm -rf ${SRC_PATH} && mkdir ${SRC_PATH}

## Build kinesis kafka connector
echo "build kinesis kafka connector..."
git clone https://github.com/awslabs/kinesis-kafka-connector.git ${SRC_PATH}/kinesis-kafka-connector \
  && cd ${SRC_PATH}/kinesis-kafka-connector \
  && mvn clean install -DskipTests
