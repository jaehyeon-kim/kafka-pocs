# MSK to Redshift Streaming Ingestion

Streaming ingestion from an MSK topic into Redshift Serverless, using an external schema over MSK and an auto refreshing materialized view instead of a Kafka sink connector.

## Stack

- `infra`, Terraform for the whole environment. It creates a VPC across 3 availability zones with 3 public and 3 private subnets and a single NAT gateway (`vpc.tf`), an MSK cluster running Kafka 3.3.1 with one `kafka.m5.large` broker per private subnet, 20 GB EBS each and IAM authentication (`msk.tf`), a Redshift Serverless namespace and workgroup with a base capacity of 128 RPUs plus a managed endpoint in the private subnets (`redshift.tf`), an S3 bucket for broker logs (`s3.tf`), and a SoftEther VPN server on a one instance auto scaling group with an elastic IP (`vpn.tf`). The VPN is what lets the developer machine reach the cluster and the Redshift endpoint in the private subnets.
- `kafka_producer`, Terraform for the producer Lambda function (`kafka_producer`, python3.8, handler `app.lambda_function`). It is wired to 5 EventBridge targets on a `rate(1 minute)` schedule, and the trigger is left disabled by `to_enable_trigger = false` in `variables.tf`.
- `kafka_producer/src/app.py` builds fake order records with Faker and sends them to the `orders` topic as JSON. It installs a fork of `kafka-python` that adds MSK IAM authentication, pinned to commit `7ff3237` in `requirements.txt`.
- `docker-compose.yml` runs `provectuslabs/kafka-ui:master` against the MSK cluster over SASL_SSL with `AWS_MSK_IAM`, so it needs AWS credentials and `BOOTSTRAP_SERVERS` in the environment.
- AWS SAM builds and invokes the producer locally against the Terraform state.
- The `CREATE EXTERNAL SCHEMA ... FROM MSK` and `CREATE MATERIALIZED VIEW` statements are not in this folder. They are in the post, and they are run against the Redshift workgroup.

## How to run

Create the infrastructure. The `vpn_to_create`, `vpn_to_use_spot` and `vpn_to_limit_vpn_ingress` variables in `infra/variables.tf` control the VPN server.

```bash
cd infra
terraform init
terraform apply
```

Connect to the VPN server, then deploy the producer.

```bash
cd ../kafka_producer
terraform init
terraform apply
```

Build the producer and invoke it locally to send messages.

```bash
sam build --hook-name terraform --beta-features
sam local invoke --hook-name terraform module.kafka_producer_lambda.aws_lambda_function.this[0] --beta-features
```

Watch the topic in the Kafka UI on `http://localhost:8080`.

```bash
docker-compose up -d
```

Then create the external schema and the materialized view in the Redshift query editor, following the post.

### Cost and tear down

This example creates paid AWS resources. The MSK cluster is three `kafka.m5.large` brokers with 20 GB of storage each, the Redshift Serverless workgroup is billed per RPU hour while it is active with a base capacity of 128 RPUs, the VPN server is an EC2 instance with an elastic IP, and the VPC has a NAT gateway. Redshift Serverless is the largest single cost here, so do not leave it running. Destroy the producer first, then the infrastructure.

```bash
cd kafka_producer && terraform destroy
cd ../infra && terraform destroy
```

## Posts

- [Simplify Streaming Ingestion on AWS – Part 1 MSK and Redshift](https://jaehyeon.me/blog/2023-02-08-simplify-streaming-ingestion-redshift/)

## Repository

[Back to the repository root](../README.md)
