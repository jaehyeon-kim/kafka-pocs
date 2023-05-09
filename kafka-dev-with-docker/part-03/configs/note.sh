curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" \
  http://localhost:8083/connectors/ \
  -d '{
        "name": "orders-sink",
        "config": {
          "connector.class": "io.confluent.connect.s3.S3SinkConnector",
          "storage.class": "io.confluent.connect.s3.storage.S3Storage",
          "format.class": "io.confluent.connect.s3.format.avro.AvroFormat",
          "tasks.max": "1",
          "topics":"ord.ods.cdc_events",
          "s3.bucket.name": "analytics-data-590312749310-ap-southeast-2",
          "s3.region": "ap-southeast-2",
          "flush.size": "100",
          "rotate.schedule.interval.ms": "60000",
          "timezone": "Australia/Sydney",
          "partitioner.class": "io.confluent.connect.storage.partitioner.DefaultPartitioner",
          "key.converter": "io.confluent.connect.avro.AvroConverter",
          "key.converter.schema.registry.url": "http://registry:8080/apis/ccompat/v6",
          "value.converter": "io.confluent.connect.avro.AvroConverter",
          "value.converter.schema.registry.url": "http://registry:8080/apis/ccompat/v6",
          "errors.log.enable": "true"
        }
  }'

curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" \
  http://localhost:8083/connectors/ -d @connector/local/sink-s3.json