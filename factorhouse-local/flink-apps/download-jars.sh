#!/usr/bin/env bash
SCRIPT_DIR="$(cd $(dirname "$0"); pwd)"

SRC_PATH=${SCRIPT_DIR}/jars

rm -rf ${SRC_PATH} && mkdir -p ${SRC_PATH}

## Download flink connectors
echo "download flink connectors..."

wget -P ${SRC_PATH} https://repo.maven.apache.org/maven2/org/apache/flink/flink-sql-connector-kafka/3.3.0-1.20/flink-sql-connector-kafka-3.3.0-1.20.jar \
  && wget -P ${SRC_PATH} https://github.com/knaufk/flink-faker/releases/download/v0.5.3/flink-faker-0.5.3.jar

  # && wget -P ${SRC_PATH} https://repo.maven.apache.org/maven2/org/apache/kafka/kafka-clients/3.3.0/kafka-clients-3.3.0.jar \