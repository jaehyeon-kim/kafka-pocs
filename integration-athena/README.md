# MSK to Athena Streaming Ingestion

Querying an MSK topic directly from Athena with the Athena MSK connector, so no pipeline is needed to land the data in S3 first.

## Stack

- `infra`, Terraform for the whole environment. It creates a VPC across 3 availability zones with 3 public and 3 private subnets and a single NAT gateway (`vpc.tf`), an MSK cluster running Kafka 3.3.1 with one `kafka.m5.large` broker per private subnet, 20 GB EBS each and IAM authentication (`msk.tf`), an S3 bucket for broker logs, connector spill and Athena results (`s3.tf`), and a SoftEther VPN server on a one instance auto scaling group with an elastic IP (`vpn.tf`). The VPN is what lets the developer machine reach the cluster in the private subnets.
- `infra/athena.tf` deploys the Athena MSK connector from the AWS Serverless Application Repository, application `AthenaMSKConnector` version `2023.8.3`, as a Lambda function named `integration-athena-ingest-orders` with `SASL_SSL_AWS_MSK_IAM` authentication and its spill prefix set to `athena-spill`. It also creates the Glue registry `customer` with a JSON schema named `orders` that maps the topic fields, and an Athena workgroup that writes results to `s3://<default bucket>/athena-output/`.
- `kafka_producer`, Terraform for the producer Lambda function (`kafka_producer`, python3.8, handler `app.lambda_function`). It is wired to 5 EventBridge targets on a `rate(1 minute)` schedule, enabled by `to_enable_trigger = true` in `variables.tf`.
- `kafka_producer/src/app.py` builds fake order records with Faker and sends them to the `orders` topic as JSON. The items list is serialised to a JSON string and the timestamp is formatted to milliseconds, because the Glue schema declares `items` as `VARCHAR` and `ordered_at` as `TIMESTAMP`. It installs a fork of `kafka-python` that adds MSK IAM authentication, pinned to commit `7ff3237` in `requirements.txt`.
- `docker-compose.yml` runs `provectuslabs/kafka-ui:master` against the MSK cluster over SASL_SSL with `AWS_MSK_IAM`, so it needs AWS credentials and `BOOTSTRAP_SERVERS` in the environment.
- AWS SAM builds and invokes the producer locally against the Terraform state.

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

Then query the topic from the Athena console, selecting the workgroup created by Terraform and the data source that the connector registered.

### Cost and tear down

This example creates paid AWS resources. The MSK cluster is three `kafka.m5.large` brokers with 20 GB of storage each, the VPN server is an EC2 instance with an elastic IP, and the VPC has a NAT gateway. All of them are billed per hour whether or not queries run. Athena charges per scanned data, and the connector Lambda function charges per invocation. Destroy the producer first, then the infrastructure.

```bash
cd kafka_producer && terraform destroy
cd ../infra && terraform destroy
```

## Posts

- [Simplify Streaming Ingestion on AWS – Part 2 MSK and Athena](https://jaehyeon.me/blog/2023-03-14-simplify-streaming-ingestion-athena/)

## Repository

[Back to the repository root](../README.md)
