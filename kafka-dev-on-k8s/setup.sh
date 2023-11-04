####
#### Kafka Cluster
####
minikube start --cpus='max' --memory=10240 --addons=metrics-server --kubernetes-version=v1.28.1

# dynamic volume provisioning
# https://minikube.sigs.k8s.io/docs/tutorials/volume_snapshots_and_csi/
minikube addons enable volumesnapshots
minikube addons enable csi-hostpath-driver
minikube addons disable storage-provisioner
minikube addons disable default-storageclass
kubectl patch storageclass csi-hostpath-sc -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

# https://kubernetes.io/docs/tutorials/stateful-application/basic-stateful-set/
# https://kubernetes.io/docs/reference/labels-annotations-taints/#apps-kubernetes.io-pod-index

kubectl create -f manifests/kafka-cluster.yml

kubectl create -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: kafka
  labels:
    app: kafka
spec:
  type: NodePort
  externalTrafficPolicy: Local
  ports:
    - port: 9092
      name: internal
  selector:
    app: kafka
EOF

kubectl create -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: kafka-ext
  labels:
    app: kafka
spec:
  type: LoadBalancer
  ports:
    - port: 29092
      name: external
  selector:
    app: kafka
EOF

kubectl run dns-test --image busybox:1.28 --rm -it --restart=Never

nslookup kafka-0.kafka:9092

kubectl run producer --image=bitnami/kafka:2.8.1 --rm -it --restart=Never \
  -- /opt/bitnami/kafka/bin/kafka-console-producer.sh --bootstrap-server kafka-0.kafka:9092 --topic my-topic

kubectl run consumer --image=bitnami/kafka:2.8.1 --rm -it --restart=Never \
  -- /opt/bitnami/kafka/bin/kafka-console-consumer.sh --bootstrap-server kafka-0.kafka:9092 --topic my-topic --from-beginning

minikube service kafka-ui --url

minikube service kafka --url

kubectl delete -f manifests/kafka-cluster.yml \
  && kubectl delete pvc kafka-data-kafka-0 \
  && kubectl delete pvc kafka-data-kafka-1

####
#### Kafka Clients
####
# use docker daemon inside minikube cluster
eval $(minikube docker-env)

docker build -t=order-clients:0.1.0 clients/.

kubectl create -f manifests/client-runner.yml
kubectl exec -it client-runner -- bash

kubectl create -f manifests/kafka-clients.yml

minikube service kafka-ui --url

kubectl delete -f manifests/kafka-clients.yml

BOOTSTRAP_SERVERS=127.0.0.1:29092 python clients/producer.py

####
#### Kafka Connect
####

# download connectors
./connect/download.sh

# use docker daemon inside minikube cluster
eval $(minikube docker-env)

docker build -t=kafka-connect:2.8.1 connect/.

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

kubectl create -f manifests/kafka-connect.yml

minikube service kafka-ui --url

## deploy source and sink connectors
kubectl run connector-creator --image=bitnami/kafka:2.8.1 --rm -it --restart=Never -- bash

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
    "s3.bucket.name": "getting-started-with-kafka-on-k8s",
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

curl http://kafka-connect:8083/connectors/order-sink/status

kubectl delete -f manifests/kafka-connect.yml