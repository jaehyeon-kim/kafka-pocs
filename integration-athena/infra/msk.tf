resource "aws_msk_cluster" "msk_data_cluster" {
  cluster_name           = "${local.name}-msk-cluster"
  kafka_version          = local.msk.version
  number_of_broker_nodes = length(module.vpc.private_subnets)
  configuration_info {
    arn      = aws_msk_configuration.msk_config.arn
    revision = aws_msk_configuration.msk_config.latest_revision
  }

  broker_node_group_info {
    instance_type   = local.msk.instance_size
    client_subnets  = module.vpc.private_subnets
    security_groups = [aws_security_group.msk.id]
    storage_info {
      ebs_storage_info {
        volume_size = local.msk.ebs_volume_size
      }
    }
  }

  client_authentication {
    sasl {
      iam = true
    }
  }

  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled   = true
        log_group = aws_cloudwatch_log_group.msk_cluster_lg.name
      }
      s3 {
        enabled = true
        bucket  = aws_s3_bucket.default_bucket.id
        prefix  = "logs/msk/cluster-"
      }
    }
  }

  tags = local.tags

  depends_on = [aws_msk_configuration.msk_config]
}

resource "aws_msk_configuration" "msk_config" {
  name = "${local.name}-msk-configuration"

  kafka_versions = [local.msk.version]

  server_properties = <<PROPERTIES
    auto.create.topics.enable = true
    delete.topic.enable = true
    log.retention.ms = ${local.msk.log_retention_ms}
  PROPERTIES
}

resource "aws_security_group" "msk" {
  name   = "${local.name}-msk-sg"
  vpc_id = module.vpc.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  tags = local.tags
}

resource "aws_security_group_rule" "msk_vpn_inbound" {
  count                    = local.vpn.to_create ? 1 : 0
  type                     = "ingress"
  description              = "VPN access"
  security_group_id        = aws_security_group.msk.id
  protocol                 = "tcp"
  from_port                = 9098
  to_port                  = 9098
  source_security_group_id = aws_security_group.vpn[0].id
}

resource "aws_security_group_rule" "msk_lambda_inbound" {
  type                     = "ingress"
  description              = "lambda access"
  security_group_id        = aws_security_group.msk.id
  protocol                 = "tcp"
  from_port                = 9098
  to_port                  = 9098
  source_security_group_id = aws_security_group.kafka_producer_lambda.id
}

resource "aws_security_group_rule" "msk_athena_connector_inbound" {
  type                     = "ingress"
  description              = "athena connector access"
  security_group_id        = aws_security_group.msk.id
  protocol                 = "tcp"
  from_port                = 9098
  to_port                  = 9098
  source_security_group_id = aws_security_group.athena_connector.id
}

# resource "aws_security_group_rule" "msk_self_inbound" {
#   type                     = "ingress"
#   description              = "allow ingress from self - required for MSK Connect"
#   security_group_id        = aws_security_group.msk.id
#   protocol                 = "-1"
#   from_port                = "0"
#   to_port                  = "0"
#   source_security_group_id = aws_security_group.msk.id
# }

resource "aws_security_group_rule" "msk_all_outbound" {
  type              = "egress"
  description       = "allow outbound all"
  security_group_id = aws_security_group.msk.id
  protocol          = "-1"
  from_port         = "0"
  to_port           = "0"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_cloudwatch_log_group" "msk_cluster_lg" {
  name = "/${local.name}/msk/cluster"

  retention_in_days = 1

  tags = local.tags
}

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
