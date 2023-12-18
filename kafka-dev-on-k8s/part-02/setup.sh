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

## local test
minikube service kafka-ui --url
minikube service demo-cluster-kafka-external-bootstrap --url

BOOTSTRAP_SERVERS=127.0.0.1:42289 python clients/producer.py
BOOTSTRAP_SERVERS=127.0.0.1:42289 python clients/consumer.py

## deploy
# use docker daemon inside minikube cluster
eval $(minikube docker-env)
# Host added: /home/jaehyeon/.ssh/known_hosts ([127.0.0.1]:32772)

docker build -t=order-clients:0.1.0 clients/.

kubectl create -f manifests/kafka-clients.yml

## delete resources
kubectl delete -f manifests/kafka-cluster.yaml
kubectl delete -f manifests/kafka-clients.yml
kubectl delete -f manifests/kafka-ui.yaml
kubectl delete -f manifests/strimzi-cluster-operator-$STRIMZI_VERSION.yaml

## delete minikube
minikube delete