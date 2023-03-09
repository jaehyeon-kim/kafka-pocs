# mks connector
# https://ap-southeast-2.console.aws.amazon.com/lambda/home?region=ap-southeast-2#/create/app?applicationId=arn:aws:serverlessrepo:us-east-1:292517598671:applications/AthenaMSKConnector
resource "aws_serverlessapplicationrepository_cloudformation_stack" "athena_msk_connector" {
  name             = "${local.name}-athena-msk-connector"
  application_id   = "arn:aws:serverlessrepo:us-east-1:292517598671:applications/AthenaMSKConnector"
  semantic_version = "2023.8.3"
  capabilities = [
    "CAPABILITY_IAM",
    "CAPABILITY_RESOURCE_POLICY",
  ]
  parameters = {
    AuthType           = "SASL_SSL_AWS_MSK_IAM"
    KafkaEndpoint      = aws_msk_cluster.msk_data_cluster.bootstrap_brokers_sasl_iam
    LambdaFunctionName = "${local.name}-ingest-orders"
    SpillBucket        = aws_s3_bucket.default_bucket.id
    SpillPrefix        = "athena-spill"
    SecurityGroupIds   = aws_security_group.athena_connector.id
    SubnetIds          = join(",", module.vpc.private_subnets)
    LambdaRoleARN      = aws_iam_role.athena_connector_role.arn
  }
}

# iam role
resource "aws_iam_role" "athena_connector_role" {
  name = "${local.name}-athena-connector-role"

  assume_role_policy = data.aws_iam_policy_document.athena_connector_assume_role_policy.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole",
    aws_iam_policy.athena_connector_permission.arn
  ]
}

data "aws_iam_policy_document" "athena_connector_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_policy" "athena_connector_permission" {
  name = "${local.name}-athena-connector-permission"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "PermissionOnCluster"
        Action = [
          "kafka-cluster:ReadData",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:Connect",
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:kafka:*:${data.aws_caller_identity.current.account_id}:cluster/*/*",
          "arn:aws:kafka:*:${data.aws_caller_identity.current.account_id}:topic/*/*"
        ]
      },
      {
        Sid = "PermissionOnGroups"
        Action = [
          "kafka:GetBootstrapBrokers"
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
      },
      {
        Sid      = "PermissionOnS3"
        Action   = ["s3:*"]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::*"
      },
      {
        Sid = "PermissionOnAthenaQuery"
        Action = [
          "athena:GetQueryExecution"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# security group
resource "aws_security_group" "athena_connector" {
  name   = "${local.name}-athena-connector"
  vpc_id = module.vpc.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  tags = local.tags
}

resource "aws_security_group_rule" "athena_connector_msk_egress" {
  type              = "egress"
  description       = "allow outbound all"
  security_group_id = aws_security_group.athena_connector.id
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}

# glue schema registry
resource "aws_glue_registry" "msk_registry" {
  registry_name = "customer"
  description   = "{AthenaFederationMSK}"

  tags = local.tags
}

resource "aws_glue_schema" "msk_schema" {
  schema_name       = "orders"
  registry_arn      = aws_glue_registry.msk_registry.arn
  data_format       = "JSON"
  compatibility     = "NONE"
  schema_definition = jsonencode({ "topicName" : "orders", "message" : { "dataFormat" : "json", "fields" : [{ "name" : "order_id", "mapping" : "order_id", "type" : "VARCHAR" }, { "name" : "ordered_at", "mapping" : "ordered_at", "type" : "TIMESTAMP", "formatHint" : "yyyy-MM-dd HH:mm:ss.SSS" }, { "name" : "user_id", "mapping" : "user_id", "type" : "VARCHAR" }, { "name" : "items", "mapping" : "items", "type" : "VARCHAR" }] } })

  tags = local.tags
}

# workgroup
resource "aws_athena_workgroup" "athena_connector" {
  name = local.name

  configuration {
    result_configuration {
      output_location = "s3://${aws_s3_bucket.default_bucket.id}/athena-output/"
    }
  }
}
