#!/usr/bin/env bash
SCRIPT_DIR="$(cd $(dirname "$0"); pwd)"

SRC_PATH=${SCRIPT_DIR}/plugins
rm -rf ${SRC_PATH} && mkdir ${SRC_PATH}

## Dwonload and build glue schema registry
echo "downloading glue schema registry..."
VERSION=v.1.1.15
DOWNLOAD_URL=https://github.com/awslabs/aws-glue-schema-registry/archive/refs/tags/$VERSION.zip
SOURCE_NAME=aws-glue-schema-registry-$VERSION

curl -L -o ${SRC_PATH}/$SOURCE_NAME.zip ${DOWNLOAD_URL} \
  && unzip -qq ${SRC_PATH}/$SOURCE_NAME.zip -d ${SRC_PATH} \
  && rm ${SRC_PATH}/$SOURCE_NAME.zip

echo "building glue schema registry..."
cd plugins/$SOURCE_NAME/build-tools \
  && mvn clean install -DskipTests -Dcheckstyle.skip \
  && cd .. \
  && mvn clean install -DskipTests \
  && mvn dependency:copy-dependencies