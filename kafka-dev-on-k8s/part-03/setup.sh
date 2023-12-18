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

# build new container images with additional connector plugins
# https://strimzi.io/docs/operators/0.27.1/using#plugins
# https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/#registry-secret-existing-credentials
kubectl create secret generic regcred \
  --from-file=.dockerconfigjson=$HOME/.docker/config.json \
  --type=kubernetes.io/dockerconfigjson

kubectl create -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: awscred
stringData:
  AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID
  AWS_SECRET_ACCESS_KEY: $AWS_SECRET_ACCESS_KEY
EOF

## deploy kafka connect cluster and connectors
kubectl create -f manifests/kafka-connect.yaml
kubectl create -f manifests/kafka-connectors.yaml

## delete resources
kubectl delete -f manifests/kafka-connectors.yaml
kubectl delete -f manifests/kafka-connect.yaml
kubectl delete secret awscred
kubectl delete secret regcred
kubectl delete -f manifests/kafka-cluster.yaml
kubectl delete -f manifests/kafka-ui.yaml
kubectl delete -f manifests/strimzi-cluster-operator-$STRIMZI_VERSION.yaml

## delete minikube
minikube delete

