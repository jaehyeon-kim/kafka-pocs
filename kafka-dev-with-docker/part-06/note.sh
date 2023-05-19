## maven
wget https://dlcdn.apache.org/maven/maven-3/3.8.8/binaries/apache-maven-3.8.8-bin.tar.gz \
  && tar xvf apache-maven-3.8.8-bin.tar.gz \
  && sudo mv apache-maven-3.8.8 /opt/maven \
  && rm apache-maven-3.8.8-bin.tar.gz

export PATH="/opt/maven/bin:$PATH"

## build
./download.sh
cd plugins/aws-glue-schema-registry-v.1.1.15/build-tools
mvn clean install -DskipTests -Dmaven.wagon.http.ssl.insecure=true
cd ..
mvn clean install -DskipTests -Dmaven.javadoc.skip=true -Dmaven.wagon.http.ssl.insecure=true 
mvn dependency:copy-dependencies


echo "building glue schema registry..."
cd plugins/$SOURCE_NAME/build-tools \
  && mvn clean install -DskipTests -Dcheckstyle.skip -Dmaven.wagon.http.ssl.insecure=true \
  && cd .. \
  && mvn clean install -DskipTests -Dmaven.wagon.http.ssl.insecure=true \
  && mvn dependency:copy-dependencies

## to do
# 1. check custom name
# 2. kafka-ui


$ mvn --version
Apache Maven 3.6.3
Maven home: /usr/share/maven
Java version: 11.0.19, vendor: Ubuntu, runtime: /usr/lib/jvm/java-11-openjdk-amd64
Default locale: en, platform encoding: UTF-8
OS name: "linux", version: "5.4.72-microsoft-standard-wsl2", arch: "amd64", family: "unix"

[INFO] ------------------------------------------------------------------------
[INFO] Reactor Summary for AWS Glue Schema Registry Library 1.1.15:
[INFO] 
[INFO] AWS Glue Schema Registry Library ................... SUCCESS [  0.644 s]
[INFO] AWS Glue Schema Registry Build Tools ............... SUCCESS [  0.038 s]
[INFO] AWS Glue Schema Registry common .................... SUCCESS [  0.432 s]
[INFO] AWS Glue Schema Registry Serializer Deserializer ... SUCCESS [  0.689 s]
[INFO] AWS Glue Schema Registry Serializer Deserializer with MSK IAM Authentication client SUCCESS [  0.216 s]
[INFO] AWS Glue Schema Registry Kafka Streams SerDe ....... SUCCESS [  0.173 s]
[INFO] AWS Glue Schema Registry Kafka Connect AVRO Converter SUCCESS [  0.190 s]
[INFO] AWS Glue Schema Registry Flink Avro Serialization Deserialization Schema SUCCESS [  0.541 s]
[INFO] AWS Glue Schema Registry examples .................. SUCCESS [  0.211 s]
[INFO] AWS Glue Schema Registry Integration Tests ......... SUCCESS [  0.648 s]
[INFO] AWS Glue Schema Registry Kafka Connect JSONSchema Converter SUCCESS [  0.239 s]
[INFO] AWS Glue Schema Registry Kafka Connect Converter for Protobuf SUCCESS [  0.296 s]
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  5.287 s
[INFO] Finished at: 2023-05-19T08:08:51+10:00
[INFO] ------------------------------------------------------------------------


# "connectorConfiguration": {
#     "connector.class": "io.confluent.connect.s3.S3SinkConnector",
#     "s3.region": "ap-southeast-2",
#     "format.class": "io.confluent.connect.s3.format.json.JsonFormat",
#     "storage.class": "io.confluent.connect.s3.storage.S3Storage",
#     "schema.compatibility": "BACKWARD",
#     "tasks.max": "1",
#     "flush.size": "2",
#     "name": "confluent-s3-sink-avro",
#     "topics.regex": "friends*",
#     "s3.bucket.name": "<backup>",
#     "key.converter.region": "ap-southeast-2",
#     "key.converter": "org.apache.kafka.connect.storage.StringConverter",
#     "value.converter.region": "ap-southeast-2",
#     "value.converter.registry.name": "testregistry",
#     "value.converter": "com.amazonaws.services.schemaregistry.kafkaconnect.AWSKafkaAvroConverter",
#     "value.converter.schemaAutoRegistrationEnabled": "true",
#     "value.convertor.schemaName": "friends",
#     "value.converter.dataFormat": "JSON",
#     "value.converter.endpoint": "https://glue.ap-southeast-2.amazonaws.com",
#     "value.converter.avroRecordType": "GENERIC_RECORD",
#     "value.converter.schemas.enable": "true"
# }

# https://github.com/awslabs/aws-glue-schema-registry/issues/93