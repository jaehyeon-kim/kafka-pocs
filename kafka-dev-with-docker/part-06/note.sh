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