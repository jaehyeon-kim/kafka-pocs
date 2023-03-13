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

data "aws_security_group" "kafka_producer_lambda" {
  name = "${local.infra_prefix}-lambda-msk-access"
}

locals {
  name        = local.infra_prefix
  region      = data.aws_region.current.name
  environment = "dev"

  infra_prefix = "integration-athena"

  producer = {
    src_path          = "src"
    function_name     = "kafka_producer"
    handler           = "app.lambda_function"
    concurrency       = 5
    timeout           = 90
    memory_size       = 128
    runtime           = "python3.8"
    schedule_rate     = "rate(1 minute)"
    to_enable_trigger = false
    environment = {
      topic_name  = "orders"
      max_run_sec = 60
    }
  }

  tags = {
    Name        = local.name
    Environment = local.environment
  }
}
