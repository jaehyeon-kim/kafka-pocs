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
      arn  = module.kafka_producer_lambda.lambda_function_arn
    }]
  }

  depends_on = [
    module.kafka_producer_lambda
  ]

  tags = local.tags
}

module "kafka_producer_lambda" {
  source = "terraform-aws-modules/lambda/aws"

  function_name          = local.producer.function_name
  handler                = local.producer.handler
  runtime                = local.producer.runtime
  timeout                = local.producer.timeout
  memory_size            = local.producer.memory_size
  source_path            = local.producer.src_path
  vpc_subnet_ids         = data.aws_subnets.private.ids
  vpc_security_group_ids = [data.aws_security_group.kafka_app_lambda.id]
  attach_network_policy  = true
  attach_policies        = true
  policies               = [aws_iam_policy.msk_lambda_producer_permission.arn]
  number_of_policies     = 1
  environment_variables = {
    BOOTSTRAP_SERVERS = data.aws_msk_cluster.msk_data_cluster.bootstrap_brokers_sasl_iam
    TOPIC_NAME        = local.producer.environment.topic_name
    REGISTRY_NAME     = local.producer.environment.registry_name
    MAX_RUN_SEC       = local.producer.environment.max_run_sec
  }

  tags = local.tags
}

resource "aws_lambda_function_event_invoke_config" "kafka_producer_lambda" {
  function_name          = module.kafka_producer_lambda.lambda_function_name
  maximum_retry_attempts = 0
}

resource "aws_lambda_permission" "allow_eventbridge" {
  count         = local.producer.to_enable_trigger ? 1 : 0
  statement_id  = "InvokeLambdaFunction"
  action        = "lambda:InvokeFunction"
  function_name = local.producer.function_name
  principal     = "events.amazonaws.com"
  source_arn    = module.eventbridge.eventbridge_rule_arns["crons"]

  depends_on = [
    module.eventbridge
  ]
}

resource "aws_iam_policy" "msk_lambda_producer_permission" {
  name = "${local.producer.function_name}-msk-lambda-producer-permission"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "PermissionOnCluster"
        Action = [
          "kafka-cluster:Connect",
          "kafka-cluster:AlterCluster",
          "kafka-cluster:DescribeCluster"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:kafka:${local.region}:${data.aws_caller_identity.current.account_id}:cluster/${local.infra_prefix}-msk-cluster/*"
      },
      {
        Sid = "PermissionOnTopics"
        Action = [
          "kafka-cluster:*Topic*",
          "kafka-cluster:WriteData",
          "kafka-cluster:ReadData"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:kafka:${local.region}:${data.aws_caller_identity.current.account_id}:topic/${local.infra_prefix}-msk-cluster/*"
      },
      {
        Sid = "PermissionOnGroups"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:DescribeGroup"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:kafka:${local.region}:${data.aws_caller_identity.current.account_id}:group/${local.infra_prefix}-msk-cluster/*"
      },
      {
        Sid = "PermissionOnGlueSchema"
        Action = [
          "glue:*Schema*",
          "glue:GetRegistry",
          "glue:CreateRegistry",
          "glue:ListRegistries",
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}


module "kafka_consumer_lambda" {
  source = "terraform-aws-modules/lambda/aws"

  function_name          = local.consumer.function_name
  handler                = local.consumer.handler
  runtime                = local.consumer.runtime
  timeout                = local.consumer.timeout
  memory_size            = local.consumer.memory_size
  source_path            = local.consumer.src_path
  vpc_subnet_ids         = data.aws_subnets.private.ids
  vpc_security_group_ids = [data.aws_security_group.kafka_app_lambda.id]
  attach_network_policy  = true
  attach_policies        = true
  policies               = [aws_iam_policy.msk_lambda_consumer_permission.arn]
  number_of_policies     = 1
  environment_variables = {
    REGISTRY_NAME = local.producer.environment.registry_name
  }

  tags = local.tags
}

resource "aws_lambda_event_source_mapping" "kafka_consumer_lambda" {
  event_source_arn  = data.aws_msk_cluster.msk_data_cluster.arn
  function_name     = module.kafka_consumer_lambda.lambda_function_name
  topics            = [local.consumer.topic_name]
  starting_position = local.consumer.starting_position
  amazon_managed_kafka_event_source_config {
    consumer_group_id = "${local.consumer.topic_name}-group-01"
  }
}

resource "aws_lambda_permission" "allow_msk" {
  statement_id  = "InvokeLambdaFunction"
  action        = "lambda:InvokeFunction"
  function_name = local.consumer.function_name
  principal     = "kafka.amazonaws.com"
  source_arn    = data.aws_msk_cluster.msk_data_cluster.arn
}

resource "aws_iam_policy" "msk_lambda_consumer_permission" {
  name = "${local.consumer.function_name}-msk-lambda-consumer-permission"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "PermissionOnKafkaCluster"
        Action = [
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:AlterGroup",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData",
          "kafka-cluster:DescribeClusterDynamicConfiguration"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:kafka:${local.region}:${data.aws_caller_identity.current.account_id}:cluster/${local.infra_prefix}-msk-cluster/*",
          "arn:aws:kafka:${local.region}:${data.aws_caller_identity.current.account_id}:topic/${local.infra_prefix}-msk-cluster/*",
          "arn:aws:kafka:${local.region}:${data.aws_caller_identity.current.account_id}:group/${local.infra_prefix}-msk-cluster/*"
        ]
      },
      {
        Sid = "PermissionOnKafka"
        Action = [
          "kafka:DescribeCluster",
          "kafka:GetBootstrapBrokers"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Sid = "PermissionOnNetwork"
        Action = [
          # The first three actions also exist in netwrok policy attachment in lambda module
          # "ec2:CreateNetworkInterface",
          # "ec2:DescribeNetworkInterfaces",
          # "ec2:DeleteNetworkInterface",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Sid = "PermissionOnGlueSchema"
        Action = [
          "glue:*Schema*",
          "glue:ListRegistries"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}
