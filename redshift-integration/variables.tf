data "aws_lambda_function" "kafka_producer_lambda" {
  function_name = local.producer.function_name

  depends_on = [
    module.kafka_producer_lambda
  ]
}

locals {
  name        = basename(path.cwd) == "infra" ? basename(dirname(path.cwd)) : basename(path.cwd)
  environment = "dev"

  producer = {
    parent_path   = "${abspath(path.module)}/lambdas"
    function_name = "kafka_producer"
    handler       = "app.lambda_function"
    concurrency   = 2
    timeout       = 90
    memory_size   = 256
    runtime       = "python3.8"
    schedule_rate = "rate(1 minute)"
  }

  tags = {
    Name        = local.name
    Environment = local.environment
  }
}
