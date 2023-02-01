resource "aws_msk_serverless_cluster" "demo" {
  cluster_name = "${local.name}-demo-cluster"

  vpc_config {
    subnet_ids = module.vpc.private_subnets
    security_group_ids = [
      aws_security_group.msk_serverless.id
    ]
  }

  client_authentication {
    sasl {
      iam {
        enabled = true
      }
    }
  }

  tags = local.tags
}

# Security group resources for vpn access
resource "aws_security_group" "msk_serverless" {
  name   = "${local.name}-msk-serverless"
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
  security_group_id        = aws_security_group.msk_serverless.id
  protocol                 = "tcp"
  from_port                = 9098
  to_port                  = 9098
  source_security_group_id = aws_security_group.vpn[0].id
}

resource "aws_security_group_rule" "msk_lambda_inbound" {
  type                     = "ingress"
  description              = "lambda access"
  security_group_id        = aws_security_group.msk_serverless.id
  protocol                 = "tcp"
  from_port                = 9098
  to_port                  = 9098
  source_security_group_id = aws_security_group.kafka_producer_lambda.id
}

resource "aws_security_group_rule" "msk_redshift_inbound" {
  type                     = "ingress"
  description              = "redshift access"
  security_group_id        = aws_security_group.msk_serverless.id
  protocol                 = "-1"
  from_port                = "0"
  to_port                  = "0"
  source_security_group_id = aws_security_group.redshift_serverless.id
}

resource "aws_security_group_rule" "msk_serverless_egress_all" {
  type              = "egress"
  description       = "outbound all"
  security_group_id = aws_security_group.msk_serverless.id
  protocol          = "-1"
  from_port         = "0"
  to_port           = "0"
  cidr_blocks       = ["0.0.0.0/0"]
}
