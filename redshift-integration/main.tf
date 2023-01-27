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

module "eventbridge" {
  source = "terraform-aws-modules/eventbridge/aws"

  create_bus = false

  rules = {
    crons = {
      description         = "Kafka producer lambda schedule"
      schedule_expression = local.producer.schedule_rate
    }
  }

  targets = {
    crons = [for i in range(local.producer.concurrency) : {
      name = "lambda-target-${i}"
      arn  = data.aws_lambda_function.kafka_producer_lambda.arn
    }]
  }

  depends_on = [
    module.kafka_producer_lambda
  ]

  tags = local.tags
}

module "kafka_producer_lambda" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = local.producer.function_name
  handler       = local.producer.handler
  runtime       = local.producer.runtime
  timeout       = local.producer.timeout
  memory_size   = local.producer.memory_size
  source_path   = "${local.producer.parent_path}/${local.producer.function_name}"

  tags = local.tags
}

resource "aws_lambda_function_event_invoke_config" "kafka_producer_lambda" {
  function_name          = module.kafka_producer_lambda.lambda_function_name
  maximum_retry_attempts = 0
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "InvokeLambdaFunction"
  action        = "lambda:InvokeFunction"
  function_name = local.producer.function_name
  principal     = "events.amazonaws.com"
  source_arn    = module.eventbridge.eventbridge_rule_arns["crons"]

  depends_on = [
    module.eventbridge
  ]
}
