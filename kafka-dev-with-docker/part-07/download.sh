#!/usr/bin/env bash
SCRIPT_DIR="$(cd $(dirname "$0"); pwd)"

## Kafka UI Glue SERDE
echo "downloading kafka ui glue serde..."
DOWNLOAD_URL=https://github.com/provectus/kafkaui-glue-sr-serde/releases/download/v1.0.3/kafkaui-glue-serde-v1.0.3-jar-with-dependencies.jar

curl -L -o ${SCRIPT_DIR}/kafkaui-glue-serde-v1.0.3-jar-with-dependencies.jar ${DOWNLOAD_URL}