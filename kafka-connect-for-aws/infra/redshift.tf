module "redshift" {
  source  = "terraform-aws-modules/redshift/aws"
  version = ">= 4.0.0, < 5.0.0"

  cluster_identifier = local.name
  node_type          = local.redshift.node_type
  number_of_nodes    = local.redshift.number_of_nodes
  port               = local.redshift.port_number

  database_name   = local.redshift.db_name
  master_username = local.redshift.admin_username
  master_password = random_password.redshift_admin_pw.result

  # Redshift network config
  subnet_ids             = module.vpc.private_subnets
  vpc_security_group_ids = [aws_security_group.redshift.id]
  publicly_accessible    = local.redshift_serverless.publicly_accessible

  # IAM Roles
  default_iam_role_arn = aws_iam_role.redshift_cluster_role.arn
  iam_role_arns        = [aws_iam_role.redshift_cluster_role.arn]
}

resource "aws_iam_role" "redshift_cluster_role" {
  name = "${local.name}-redshift-cluster-role"

  assume_role_policy = data.aws_iam_policy_document.redshift_cluster_assume_role_policy.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AWSGlueConsoleFullAccess",
    "arn:aws:iam::aws:policy/AmazonRedshiftFullAccess",
    "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
  ]
}

data "aws_iam_policy_document" "redshift_cluster_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "redshift.amazonaws.com",
        "sagemaker.amazonaws.com",
        "events.amazonaws.com",
        "scheduler.redshift.amazonaws.com"
      ]
    }

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

resource "aws_security_group" "redshift" {
  name   = "${local.name}-redshift-security-group"
  vpc_id = module.vpc.vpc_id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "redshift_vpn_inbound" {
  count                    = local.vpn.to_create ? 1 : 0
  type                     = "ingress"
  description              = "VPN access"
  security_group_id        = aws_security_group.redshift.id
  protocol                 = "tcp"
  from_port                = local.redshift.port_number
  to_port                  = local.redshift.port_number
  source_security_group_id = aws_security_group.vpn[0].id
}

resource "aws_security_group_rule" "redshift_firehose_ingress" {
  count             = local.firehose.to_create ? 1 : 0
  type              = "ingress"
  description       = "firehose access"
  security_group_id = aws_security_group.redshift.id
  protocol          = "tcp"
  from_port         = 5439
  to_port           = 5439
  cidr_blocks       = [local.firehose.cidr_block]
}

resource "aws_security_group_rule" "redshift_msk_ingress" {
  count                    = local.msk.to_create ? 1 : 0
  type                     = "ingress"
  description              = "MSK access"
  security_group_id        = aws_security_group.redshift.id
  protocol                 = "tcp"
  from_port                = 5439
  to_port                  = 5439
  source_security_group_id = aws_security_group.msk[0].id
}


resource "random_password" "redshift_admin_pw" {
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "redshift_secrets" {
  name                    = "${local.name}-redshift-secrets"
  description             = "Redshift secrets"
  recovery_window_in_days = 0

  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "redshift_secrets" {
  secret_id     = aws_secretsmanager_secret.redshift_secrets.id
  secret_string = <<EOF
  {
    "password": "${random_password.redshift_admin_pw.result}"
  }
EOF
}
