# iam role
resource "aws_iam_role" "athena_connector_role" {
  name = "${local.name}-athena-connector-role"

  assume_role_policy = data.aws_iam_policy_document.athena_connector_assume_role_policy.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole",
    aws_iam_policy.msk_redshift_permission.arn
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
      }
    ]
  })
}

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
  description       = "lambda msk access"
  security_group_id = aws_security_group.athena_connector.id
  protocol          = "tcp"
  from_port         = 9098
  to_port           = 9098
  cidr_blocks       = ["0.0.0.0/0"]
}
