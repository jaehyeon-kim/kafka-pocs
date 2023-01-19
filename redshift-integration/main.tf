terraform {
  required_version = ">= 1.0.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.72"
    }

    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.1"
    }
  }
}

module "kafka_producer" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "kafka_producer"
  handler       = "app.lambda_function"
  runtime       = "python3.8"
  source_path   = "${local.lambda_parent_path}/kafka_producer"
}
