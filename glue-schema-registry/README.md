# Glue Schema Registry Demo

Python Kafka producer and consumer Lambda functions that serialise and deserialise Avro messages on an MSK cluster through the AWS Glue Schema Registry.

## Stack

- `infra`, Terraform for the shared infrastructure. It creates a VPC across 3 availability zones with 3 public and 3 private subnets and a single NAT gateway (`vpc.tf`), an MSK cluster running Kafka 3.3.1 with one `kafka.m5.large` broker per private subnet, 20 GB EBS each and IAM authentication (`msk.tf`), an S3 bucket for broker logs (`s3.tf`), and a SoftEther VPN server on a one instance auto scaling group with an elastic IP (`vpn.tf`). The VPN is what lets the developer machine reach the cluster in the private subnets.
- `app`, Terraform for the two Lambda functions. The producer (`kafka_producer`, python3.8) is invoked by 5 EventBridge targets on a `rate(1 minute)` schedule. The consumer (`kafka_consumer`, python3.8) is driven by an MSK event source mapping on the `orders` topic. Both use the registry named `customer`.
- `app/producer` builds fake order records with Faker, derives the Avro schema from a dataclass with `dataclasses-avroschema`, and serialises with `aws-schema-registry`. `app/consumer` deserialises the same records. Both install a fork of `kafka-python` that adds MSK IAM authentication, pinned to commit `7ff3237` in `requirements.txt`.
- `compose-demo.yml` runs a local single broker cluster, `docker.io/bitnami/zookeeper:3.8` and `docker.io/bitnami/kafka:3.3`, for the schema evolution walkthrough. `compose-local.yml` is the same cluster plus Kpow `factorhouse/kpow-ce:91.2.1`. `docker-compose.yml` runs Kpow on its own against the MSK cluster over SASL_SSL with `AWS_MSK_IAM`.
- AWS SAM builds and invokes the Lambda functions locally against the Terraform state.

## How to run

Create the infrastructure. The `vpn_to_create`, `vpn_to_use_spot` and `vpn_to_limit_vpn_ingress` variables in `infra/variables.tf` control the VPN server.

```bash
cd infra
terraform init
terraform apply
```

Connect to the VPN server, then deploy the two Lambda functions.

```bash
cd ../app
terraform init
terraform apply
```

Build and invoke the producer locally.

```bash
sam build --hook-name terraform --beta-features
sam local invoke --hook-name terraform module.kafka_producer_lambda.aws_lambda_function.this[0] --beta-features
```

Run Kpow against the MSK cluster. It needs `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`, `AWS_DEFAULT_REGION`, `BOOTSTRAP_SERVERS` and `SCHEMA_REGISTRY_ARN` in the environment, and it fails to start if the registry does not exist.

```bash
docker-compose up -d
```

The local cluster used for the schema evolution walkthrough needs no AWS account.

```bash
docker-compose -f compose-demo.yml up -d
```

### Cost and tear down

This example creates paid AWS resources. The MSK cluster is three `kafka.m5.large` brokers with 20 GB of storage each, the VPN server is an EC2 instance with an elastic IP, and the VPC has a NAT gateway. All of them are billed per hour whether or not messages flow. Destroy the applications first, then the infrastructure.

```bash
cd app && terraform destroy
cd ../infra && terraform destroy
```

## Posts

- [Integrate Glue Schema Registry with Your Python Kafka App](https://jaehyeon.me/blog/2023-04-12-integrate-glue-schema-registry/)

## Repository

[Back to the repository root](../README.md)

## Bitnami images

Bitnami's public Docker images have been moved to the [**Bitnami Legacy**](https://hub.docker.com/u/bitnamilegacy) repository. To ensure continued access and compatibility, please update your Docker image references accordingly.

For example:

- `bitnami/kafka:3.3` → `bitnamilegacy/kafka:3.3`
- `bitnami/zookeeper:3.8` → `bitnamilegacy/zookeeper:3.8`
