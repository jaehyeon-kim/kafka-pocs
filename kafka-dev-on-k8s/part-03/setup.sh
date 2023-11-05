## create minikube cluster
minikube start --cpus='max' --memory=10240 --addons=metrics-server --kubernetes-version=v1.24.7

## download and deploy strimzi oeprator
STRIMZI_VERSION="0.27.1"
DOWNLOAD_URL=https://github.com/strimzi/strimzi-kafka-operator/releases/download/$STRIMZI_VERSION/strimzi-cluster-operator-$STRIMZI_VERSION.yaml
curl -L -o manifests/strimzi-cluster-operator-$STRIMZI_VERSION.yaml ${DOWNLOAD_URL}

sed -i 's/namespace: .*/namespace: default/' manifests/strimzi-cluster-operator-$STRIMZI_VERSION.yaml
kubectl create -f manifests/strimzi-cluster-operator-$STRIMZI_VERSION.yaml

kubectl create -f manifests/kafka-cluster.yaml
kubectl create -f manifests/kafka-ui.yaml

minikube service kafka-ui --url

# use docker daemon inside minikube cluster
eval $(minikube docker-env)
# Host added: /home/jaehyeon/.ssh/known_hosts ([127.0.0.1]:32772)

./connect/download.sh
docker build -t=kafka-connect:2.8.1 connect/.

## deploy kafka connect
kubectl create configmap connect-props \
  --from-file=connect-distributed.properties=connect/configs/connect-distributed.properties

kubectl create -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: aws-creds
stringData:
  AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID
  AWS_SECRET_ACCESS_KEY: $AWS_SECRET_ACCESS_KEY
  AWS_SESSION_TOKEN: $AWS_SESSION_TOKEN
EOF

kubectl create -f manifests/kafka-connect.yaml

## deploy connectors
kubectl run tmp --image=bitnami/kafka:2.8.1 --rm -it --restart=Never -- bash

cat <<EOF > /tmp/source.json
{
  "name": "order-source",
  "config": {
    "connector.class": "com.amazonaws.mskdatagen.GeneratorSourceConnector",
    "tasks.max": "2",
    "key.converter": "org.apache.kafka.connect.storage.StringConverter",
    "key.converter.schemas.enable": false,
    "value.converter": "org.apache.kafka.connect.json.JsonConverter",
    "value.converter.schemas.enable": false,

    "genkp.customer.with": "#{Code.isbn10}",
    "genv.customer.name.with": "#{Name.full_name}",

    "genkp.order.with": "#{Internet.uuid}",
    "genv.order.product_id.with": "#{number.number_between '101','109'}",
    "genv.order.quantity.with": "#{number.number_between '1','5'}",
    "genv.order.customer_id.matching": "customer.key",

    "global.throttle.ms": "500",
    "global.history.records.max": "1000"
  }
}
EOF

cat <<EOF > /tmp/sink.json
{
  "name": "order-sink",
  "config": {
    "connector.class": "io.confluent.connect.s3.S3SinkConnector",
    "storage.class": "io.confluent.connect.s3.storage.S3Storage",
    "format.class": "io.confluent.connect.s3.format.json.JsonFormat",
    "tasks.max": "2",
    "topics": "order,customer",
    "s3.bucket.name": "kafka-dev-on-k8s",
    "s3.region": "ap-southeast-2",
    "flush.size": "100",
    "rotate.schedule.interval.ms": "60000",
    "timezone": "Australia/Sydney",
    "partitioner.class": "io.confluent.connect.storage.partitioner.DefaultPartitioner",
    "key.converter": "org.apache.kafka.connect.storage.StringConverter",
    "key.converter.schemas.enable": false,
    "value.converter": "org.apache.kafka.connect.json.JsonConverter",
    "value.converter.schemas.enable": false,
    "errors.log.enable": "true"
  }
}
EOF

curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" \
  http://kafka-connect:8083/connectors/ -d @/tmp/source.json

curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" \
  http://kafka-connect:8083/connectors/ -d @/tmp/sink.json

curl http://kafka-connect:8083/connectors/

curl http://kafka-connect:8083/connectors/order-source/status
curl http://kafka-connect:8083/connectors/order-sink/status

kubectl delete -f manifests/kafka-connect.yml

## delete resources
kubectl delete -f manifests/kafka-ui.yaml
kubectl delete -f manifests/kafka-connect.yaml
kubectl delete -f manifests/kafka-cluster.yaml
kubectl delete -f manifests/strimzi-cluster-operator-$STRIMZI_VERSION.yaml

## delete minikube
minikube delete