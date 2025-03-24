docker-compose -f kpow-trial.yml up -d \
  && EXT_NET=true docker-compose -f flex-trial.yml up -d

docker-compose -f kpow-trial.yml down --remove-orphans -v

docker-compose -f lakehouse.yml up -d
# https://blog.min.io/a-developers-introduction-to-apache-iceberg-using-minio/
# https://github.com/databricks/docker-spark-iceberg

# flex pricing per server or per workload?
# FLINK_REST_URL=http://jobmanager:8081 ## fail without protocol eg) jobmanager:8081