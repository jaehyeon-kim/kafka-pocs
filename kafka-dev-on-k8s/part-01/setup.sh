## create minikube cluster
minikube start --cpus='max' --memory=10240 --addons=metrics-server --kubernetes-version=v1.24.7

# dynamic volume provisioning
# https://minikube.sigs.k8s.io/docs/tutorials/volume_snapshots_and_csi/
minikube addons enable volumesnapshots
minikube addons enable csi-hostpath-driver
minikube addons disable storage-provisioner
minikube addons disable default-storageclass
kubectl patch storageclass csi-hostpath-sc -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

## download and deploy strimzi oeprator
STRIMZI_VERSION="0.27.1"
DOWNLOAD_URL=https://github.com/strimzi/strimzi-kafka-operator/releases/download/$STRIMZI_VERSION/strimzi-cluster-operator-$STRIMZI_VERSION.yaml
curl -L -o manifests/strimzi-cluster-operator-$STRIMZI_VERSION.yaml ${DOWNLOAD_URL}

sed -i 's/namespace: .*/namespace: default/' manifests/strimzi-cluster-operator-$STRIMZI_VERSION.yaml
kubectl create -f manifests/strimzi-cluster-operator-$STRIMZI_VERSION.yaml

kubectl create -f manifests/kafka-cluster.yaml
kubectl create -f manifests/kafka-ui.yaml

kubectl get service demo-cluster-kafka-external-bootstrap -o=jsonpath='{.status.loadBalancer.ingress[0].hostname}{"\n"}'
kubectl get service demo-cluster-kafka-external-bootstrap -o=jsonpath='{.status.loadBalancer.ingress[0].ip}{"\n"}'

kubectl run kafka-producer --image=quay.io/strimzi/kafka:0.27.1-kafka-2.8.1 --rm -it --restart=Never \
  -- bin/kafka-console-producer.sh --bootstrap-server demo-cluster-kafka-bootstrap:9092 --topic demo-topic

kubectl run kafka-consumer --image=quay.io/strimzi/kafka:0.27.1-kafka-2.8.1 --rm -it --restart=Never \
  -- bin/kafka-console-consumer.sh --bootstrap-server demo-cluster-kafka-bootstrap:9092 --topic demo-topic --from-beginning

minikube service kafka-ui --url
