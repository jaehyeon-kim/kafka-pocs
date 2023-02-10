#!/bin/bash

sudo rm -rf .bitnami

mkdir -p \
  .bitnami/zookeeper/data \
  .bitnami/kafka_0/data .bitnami/kafka_0/logs \
  .bitnami/kafka_1/data .bitnami/kafka_1/logs \
  .bitnami/kafka_2/data .bitnami/kafka_2/logs \
  && chmod 777 -R .bitnami