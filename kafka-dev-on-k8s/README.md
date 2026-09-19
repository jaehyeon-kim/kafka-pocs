# Kafka Development on Kubernetes

A Kafka cluster run on minikube by the Strimzi operator, then a Python producer and consumer deployed beside it, then a Kafka Connect cluster built by Strimzi with an S3 sink.

## Parts

| Folder | What it does | Post |
|---|---|---|
| [part-01](./part-01) | Installs the Strimzi operator, creates a two broker Kafka cluster and deploys Kafka UI. | [Kafka Development on Kubernetes - Part 1 Cluster Setup](https://jaehyeon.me/blog/2023-12-21-kafka-development-on-k8s-part-1/) |
| [part-02](./part-02) | Adds a Python producer and consumer, run first on the host and then as deployments from an image built inside minikube. | [Kafka Development on Kubernetes - Part 2 Producer and Consumer](https://jaehyeon.me/blog/2024-01-04-kafka-development-on-k8s-part-2/) |
| [part-03](./part-03) | Adds a Kafka Connect cluster that Strimzi builds with two plugins, plus source and sink connectors managed as `KafkaConnector` resources. | [Kafka Development on Kubernetes - Part 3 Kafka Connect](https://jaehyeon.me/blog/2024-01-11-kafka-development-on-k8s-part-3/) |

Each part is self contained. `setup.sh` in each folder is the full sequence for that part, including the delete commands at the end.

## Stack

- minikube on Kubernetes `v1.24.7`, started with `--cpus='max' --memory=10240 --addons=metrics-server`.
- Strimzi cluster operator `0.27.1`. `setup.sh` downloads the release manifest and rewrites its namespace to `default` before applying it, so the copy under `manifests` is a downloaded artefact rather than hand written.
- `manifests/kafka-cluster.yaml` defines a `Kafka` resource named `demo-cluster`, Kafka `2.8.1`, 2 brokers with 20 GiB persistent claims and 1 ZooKeeper node with a 10 GiB claim. It exposes a plain internal listener on 9092 and an external nodeport listener on 29092, and defaults topics to 3 partitions.
- `manifests/kafka-ui.yaml` deploys `provectuslabs/kafka-ui:v0.7.1` as a service reached through `minikube service kafka-ui --url`.
- part-02 `clients/producer.py` and `clients/consumer.py` use `kafka-python` and `Faker`. `clients/Dockerfile` builds them on `bitnami/python:3.8` as `order-clients:0.1.0`. `manifests/kafka-clients.yml` runs one producer and one consumer deployment against `demo-cluster-kafka-bootstrap:9092` on the `orders` topic, with `imagePullPolicy: Never` because the image only exists in the minikube Docker daemon.
- part-03 `manifests/kafka-connect.yaml` defines a `KafkaConnect` resource named `demo-connect`, version 2.8.1, 2 replicas. Strimzi builds the worker image from two plugins, the Confluent S3 sink `10.4.3` and the MSK Data Generator `0.4.0`, and pushes it to `jaehyeon/demo-connect:latest` using the `regcred` secret. AWS credentials are injected from the `awscred` secret.
- part-03 `manifests/kafka-connectors.yaml` defines two `KafkaConnector` resources: `order-source` generating `customer` and `order` records, and `order-sink` writing both topics as JSON to the S3 bucket `kafka-dev-on-k8s-ap-southeast-2` in `ap-southeast-2`.

## How to run

Run the commands from inside the part folder, because the manifest paths are relative. This is part 1.

```bash
cd part-01
minikube start --cpus='max' --memory=10240 --addons=metrics-server --kubernetes-version=v1.24.7

STRIMZI_VERSION="0.27.1"
curl -L -o manifests/strimzi-cluster-operator-$STRIMZI_VERSION.yaml \
  https://github.com/strimzi/strimzi-kafka-operator/releases/download/$STRIMZI_VERSION/strimzi-cluster-operator-$STRIMZI_VERSION.yaml
sed -i 's/namespace: .*/namespace: default/' manifests/strimzi-cluster-operator-$STRIMZI_VERSION.yaml
kubectl create -f manifests/strimzi-cluster-operator-$STRIMZI_VERSION.yaml

kubectl create -f manifests/kafka-cluster.yaml
kubectl create -f manifests/kafka-ui.yaml
minikube service kafka-ui --url
```

Part 2 adds the client image and its deployments. The image must be built against the minikube Docker daemon, or the pods cannot find it.

```bash
eval $(minikube docker-env)
docker build -t=order-clients:0.1.0 clients/.
kubectl create -f manifests/kafka-clients.yml
```

Part 3 adds the two secrets and the Connect resources. `regcred` is the Docker registry credential that Strimzi uses to push the built worker image, and `awscred` holds the keys the S3 sink uses.

```bash
kubectl create secret generic regcred \
  --from-file=.dockerconfigjson=$HOME/.docker/config.json \
  --type=kubernetes.io/dockerconfigjson

kubectl create -f manifests/kafka-connect.yaml
kubectl create -f manifests/kafka-connectors.yaml
```

### Cost and tear down

Parts 1 and 2 run entirely on minikube and create no AWS resources. Part 3 writes objects to an S3 bucket you own and needs an AWS access key, so S3 storage and requests are charged, and the built worker image is pushed to the container registry named in `kafka-connect.yaml`. Delete the Kubernetes resources and then the cluster itself. The commands for each part are at the end of its `setup.sh`.

```bash
kubectl delete -f manifests/kafka-connectors.yaml
kubectl delete -f manifests/kafka-connect.yaml
kubectl delete secret awscred
kubectl delete secret regcred
kubectl delete -f manifests/kafka-cluster.yaml
kubectl delete -f manifests/kafka-ui.yaml
kubectl delete -f manifests/strimzi-cluster-operator-0.27.1.yaml

minikube delete
```

Empty the S3 bucket separately if the sink connector has written to it.

## Posts

- [Kafka Development on Kubernetes - Part 1 Cluster Setup](https://jaehyeon.me/blog/2023-12-21-kafka-development-on-k8s-part-1/)
- [Kafka Development on Kubernetes - Part 2 Producer and Consumer](https://jaehyeon.me/blog/2024-01-04-kafka-development-on-k8s-part-2/)
- [Kafka Development on Kubernetes - Part 3 Kafka Connect](https://jaehyeon.me/blog/2024-01-11-kafka-development-on-k8s-part-3/)

## Repository

[Back to the repository root](../README.md)

## Bitnami images

Bitnami's public Docker images have been moved to the [**Bitnami Legacy**](https://hub.docker.com/u/bitnamilegacy) repository. To ensure continued access and compatibility, please update your Docker image references accordingly. This folder has no compose file, but `part-02/clients/Dockerfile` builds on a Bitnami image.

For example:

- `bitnami/python:3.8` → `bitnamilegacy/python:3.8`
