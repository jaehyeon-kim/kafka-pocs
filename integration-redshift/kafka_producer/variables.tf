# Region in which to deploy the solution
data "aws_region" "current" {}

data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = ["${infra_prefix}-vpc"]
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
  cluster_name = "${infra_prefix}-msk-cluster"
}

data "aws_security_group" "kafka_producer_lambda" {
  name = "${infra_prefix}-lambda-msk-access"
}

locals {
  name        = basename(path.cwd) == "infra" ? basename(dirname(path.cwd)) : basename(path.cwd)
  region      = data.aws_region.current.name
  environment = "dev"

  infra_prefix = "integration-redshift"

  producer = {
    src_path          = "src"
    function_name     = "kafka_producer"
    handler           = "app.lambda_function"
    concurrency       = 2
    timeout           = 90
    memory_size       = 256
    runtime           = "python3.8"
    schedule_rate     = "rate(1 minute)"
    to_enable_trigger = false
    environment = {
      topic_name  = "test"
      max_run_sec = 10
    }
  }

  tags = {
    Name        = local.name
    Environment = local.environment
  }
}
