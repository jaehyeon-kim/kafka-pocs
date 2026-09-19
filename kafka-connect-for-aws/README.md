# Kafka Connect for AWS Integration

A Camel DynamoDB sink connector, first developed against a local Kafka Connect cluster, then deployed to MSK Connect with Terraform. The MSK Data Generator source connector produces the order records both times.

## Parts

| Folder | What it does | Post |
|---|---|---|
| (no folder) | Introduction to the series. It compares the connector options and creates no resources. | [Kafka Connect for AWS Services Integration - Part 1 Introduction](https://jaehyeon.me/blog/2023-05-03-kafka-connect-for-aws-part-1/) |
| [part-02](./part-02) | Local Kafka Connect cluster in distributed mode, source and sink connectors registered over the REST API, records landing in a DynamoDB table. | [Kafka Connect for AWS Services Integration - Part 2 Develop Camel DynamoDB Sink Connector](https://jaehyeon.me/blog/2023-06-04-kafka-connect-for-aws-part-2/) |
| [part-03](./part-03) | The same two connectors deployed on MSK Connect, with the MSK cluster, the DynamoDB table and the custom plugins created by Terraform. | [Kafka Connect for AWS Services Integration - Part 3 Deploy Camel DynamoDB Sink Connector](https://jaehyeon.me/blog/2023-07-03-kafka-connect-for-aws-part-3/) |

Parts 4 and 5 of the series cover an Aiven OpenSearch sink connector and their code lives in the `opensearch-kafka-connect` folder of the [general-demos](https://github.com/jaehyeon-kim/general-demos) repository, not here.

## Stack

### part-02

- A three broker Kafka cluster, `bitnami/zookeeper:3.5` and `bitnami/kafka:2.8.1`, in `compose-kafka.yml`. Each broker has an internal listener on port 9092 and an external listener on `localhost:29092`, `29093` and `29094`. Topics default to 3 partitions and a replication factor of 3.
- A single Kafka Connect worker in `compose-connect.yml`, running `connect-distributed.sh` inside the same `bitnami/kafka:2.8.1` image, with the REST API on `http://localhost:8083`. `configs/connect-distributed.properties` sets `plugin.path=/opt/connectors`, and the connector jars are mounted there.
- `provectuslabs/kafka-ui:master` in `compose-ui.yml`, on `http://localhost:8080`, configured to see both the cluster and the Connect worker.
- `download.sh` fetches the two plugins into `connectors`, which is excluded by `.gitignore`: the MSK Data Generator `0.4.0` jar and the Camel AWS DDB Sink connector `3.20.3` package. It also zips the Camel connector, so the same script prepares the archive that part 3 uploads to S3.
- `configs/source.json` and `configs/sink.json` are the connector definitions. `configs/ddb.json` is the DynamoDB table definition, and `configs/note.sh` holds the curl and AWS CLI commands used in the post.

### part-03

- Terraform for everything. It creates a VPC across 3 availability zones with 3 public and 3 private subnets and a single NAT gateway (`vpc.tf`), an MSK cluster running Kafka 2.8.1 with one `kafka.m5.large` broker per private subnet, 20 GB EBS each and IAM authentication (`msk.tf`), an S3 bucket (`s3.tf`), a provisioned DynamoDB table named `connect-for-aws-orders` with one read and one write capacity unit and a `customer` global secondary index (`ddb.tf`), and a SoftEther VPN server on a one instance auto scaling group with an elastic IP (`vpn.tf`).
- `msk-connect.tf` uploads the zipped Camel connector to S3, registers it as an MSK Connect custom plugin, and creates the two MSK Connect connectors, each with 1 MCU and 1 worker, on Kafka Connect version 2.7.1, logging to CloudWatch and S3.
- `docker-compose.yml` runs Kpow `factorhouse/kpow-ce:91.2.1` on `http://localhost:3000` against the MSK cluster over SASL_SSL with `AWS_MSK_IAM`.
- `download.sh` is the same script as in part 2 and must be run before `terraform apply`, because `msk-connect.tf` reads `connectors/camel-aws-ddb-sink-kafka-connector.zip` from disk.

## How to run

### part-02

```bash
cd part-02
./download.sh
docker-compose -f compose-kafka.yml up -d
docker-compose -f compose-connect.yml up -d
docker-compose -f compose-ui.yml up -d
```

Create the DynamoDB table, then register the two connectors. The commands are in `configs/note.sh`.

```bash
aws dynamodb create-table --cli-input-json file://configs/ddb.json

curl -i -X POST -H "Accept:application/json" -H "Content-Type:application/json" \
  http://localhost:8083/connectors/ -d @configs/source.json
curl -i -X POST -H "Accept:application/json" -H "Content-Type:application/json" \
  http://localhost:8083/connectors/ -d @configs/sink.json
```

Bring it down in the reverse order, then delete the DynamoDB table.

```bash
docker-compose -f compose-ui.yml down
docker-compose -f compose-connect.yml down
docker-compose -f compose-kafka.yml down
aws dynamodb delete-table --table-name orders
```

The Kafka cluster and the Connect worker run locally. The DynamoDB table is the only AWS resource, and at one read and one write capacity unit it is inexpensive, but it is still charged until it is deleted.

### part-03

```bash
cd part-03
./download.sh
terraform init
terraform apply
```

Connect to the VPN server to reach the cluster, then run Kpow to watch the topic and the connectors.

```bash
docker-compose up -d
```

### Cost and tear down

Part 3 creates paid AWS resources. The MSK cluster is three `kafka.m5.large` brokers with 20 GB of storage each, the two MSK Connect connectors are billed per MCU hour, the VPN server is an EC2 instance with an elastic IP, and the VPC has a NAT gateway. All of them are billed per hour whether or not records flow.

```bash
terraform destroy
```

## Posts

- [Kafka Connect for AWS Services Integration - Part 1 Introduction](https://jaehyeon.me/blog/2023-05-03-kafka-connect-for-aws-part-1/)
- [Kafka Connect for AWS Services Integration - Part 2 Develop Camel DynamoDB Sink Connector](https://jaehyeon.me/blog/2023-06-04-kafka-connect-for-aws-part-2/)
- [Kafka Connect for AWS Services Integration - Part 3 Deploy Camel DynamoDB Sink Connector](https://jaehyeon.me/blog/2023-07-03-kafka-connect-for-aws-part-3/)

## Repository

[Back to the repository root](../README.md)

## Bitnami images

Bitnami's public Docker images have been moved to the [**Bitnami Legacy**](https://hub.docker.com/u/bitnamilegacy) repository. To ensure continued access and compatibility, please update your Docker image references accordingly.

For example:

- `bitnami/kafka:2.8.1` → `bitnamilegacy/kafka:2.8.1`
- `bitnami/zookeeper:3.5` → `bitnamilegacy/zookeeper:3.5`
