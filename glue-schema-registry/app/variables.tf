data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = ["${local.infra_prefix}"]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }

  tags = {
    Tier = "Private"
  }
}

data "aws_msk_cluster" "msk_data_cluster" {
  cluster_name = "${local.infra_prefix}-msk-cluster"
}

data "aws_security_group" "kafka_app_lambda" {
  name = "${local.infra_prefix}-lambda-msk-access"
}

locals {
  name        = local.infra_prefix
  region      = data.aws_region.current.name
  environment = "dev"

  infra_prefix = "glue-schema-registry"

  producer = {
    src_path          = "producer"
    function_name     = "kafka_producer"
    handler           = "lambda_handler.lambda_function"
    concurrency       = 5
    timeout           = 90
    memory_size       = 128
    runtime           = "python3.8"
    schedule_rate     = "rate(1 minute)"
    to_enable_trigger = true
    environment = {
      topic_name    = "orders"
      registry_name = "customer"
      max_run_sec   = 60
    }
  }

  consumer = {
    src_path          = "consumer"
    function_name     = "kafka_consumer"
    handler           = "lambda_handler.lambda_function"
    timeout           = 90
    memory_size       = 128
    runtime           = "python3.8"
    topic_name        = "orders"
    starting_position = "TRIM_HORIZON"
    environment = {
      registry_name = "customer"
    }
  }

  tags = {
    Name        = local.name
    Environment = local.environment
  }
}
