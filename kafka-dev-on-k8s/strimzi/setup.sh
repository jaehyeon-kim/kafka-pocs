https://strimzi.io/docs/operators/0.27.1/using
https://strimzi.io/docs/operators/0.27.1/overview
https://strimzi.io/docs/operators/0.27.1/quickstart
https://strimzi.io/downloads/

minikube start --cpus='max' --memory=10240 --addons=metrics-server --kubernetes-version=v1.24.7

kubectl create ns kafka

sed -i 's/namespace: .*/namespace: kafka/' strimzi/strimzi-cluster-operator-0.27.1.yaml

kubectl create -f strimzi/strimzi-cluster-operator-0.27.1.yaml -n kafka

kubectl create -f strimzi/kafka-cluster.yaml -n kafka


kubectl delete -f strimzi/strimzi-cluster-operator-0.27.1.yaml -n kafka

kubectl delete -f strimzi/kafka-cluster.yaml -n kafka


minikube service demo-cluster-kafka-external-bootstrap -n kafka --url

BOOTSTRAP_SERVERS=127.0.0.1:39833 python clients/producer.py