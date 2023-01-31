# module "eventbridge" {
#   source = "terraform-aws-modules/eventbridge/aws"

#   create_bus = false

#   rules = {
#     crons = {
#       description         = "Kafka producer lambda schedule"
#       schedule_expression = local.producer.schedule_rate
#     }
#   }

#   targets = {
#     crons = [for i in range(local.producer.concurrency) : {
#       name = "lambda-target-${i}"
#       arn  = data.aws_lambda_function.kafka_producer_lambda.arn
#     }]
#   }

#   depends_on = [
#     module.kafka_producer_lambda
#   ]

#   tags = local.tags
# }

module "kafka_producer_lambda" {
  source = "terraform-aws-modules/lambda/aws"

  function_name          = local.producer.function_name
  handler                = local.producer.handler
  runtime                = local.producer.runtime
  timeout                = local.producer.timeout
  memory_size            = local.producer.memory_size
  source_path            = "${local.producer.parent_path}/${local.producer.function_name}"
  vpc_subnet_ids         = module.vpc.private_subnets
  vpc_security_group_ids = [aws_security_group.kafka_producer_lambda.id]
  attach_network_policy  = true
  attach_policies        = true
  policies               = [aws_iam_policy.kafka_producer_lambda_permission.arn]

  tags = local.tags
}

# resource "aws_lambda_function_event_invoke_config" "kafka_producer_lambda" {
#   function_name          = module.kafka_producer_lambda.lambda_function_name
#   maximum_retry_attempts = 0
# }

# resource "aws_lambda_permission" "allow_eventbridge" {
#   statement_id  = "InvokeLambdaFunction"
#   action        = "lambda:InvokeFunction"
#   function_name = local.producer.function_name
#   principal     = "events.amazonaws.com"
#   source_arn    = module.eventbridge.eventbridge_rule_arns["crons"]

#   depends_on = [
#     module.eventbridge
#   ]
# }

resource "aws_security_group" "kafka_producer_lambda" {
  name   = "${local.name}-lambda-msk-access"
  vpc_id = module.vpc.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  tags = local.tags
}

resource "aws_security_group_rule" "kafka_producer_lambda_msk_egress" {
  type              = "egress"
  description       = "lambda msk access"
  security_group_id = aws_security_group.kafka_producer_lambda.id
  protocol          = "tcp"
  from_port         = 9098
  to_port           = 9098
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_iam_policy" "kafka_producer_lambda_permission" {
  name = "${local.name}-lambda-kafka-permissions"

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
        Resource = "arn:aws:kafka:${local.region}:${data.aws_caller_identity.current.account_id}:cluster/${local.name}-demo-cluster/*"
      },
      {
        Sid = "PermissionOnTopics"
        Action = [
          "kafka-cluster:*Topic*",
          "kafka-cluster:WriteData",
          "kafka-cluster:ReadData"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:kafka:${local.region}:${data.aws_caller_identity.current.account_id}:topic/${local.name}-demo-cluster/*"
      },
      {
        Sid = "PermissionOnGroups"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:DescribeGroup"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:kafka:${local.region}:${data.aws_caller_identity.current.account_id}:group/${local.name}-demo-cluster/*"
      }
    ]
  })
}
