## kinesis connector
resource "aws_mskconnect_connector" "kinesis_connector" {
  count = local.msk.to_create && local.msk.connectors.kinesis ? 1 : 0
  name  = "${local.name}-kinesis-connector"

  kafkaconnect_version = "2.7.1"

  capacity {
    provisioned_capacity {
      mcu_count    = 1
      worker_count = 1
    }
  }

  connector_configuration = {
    "connector.class" = "com.github.jcustenborder.kafka.connect.simulator.SimulatorSinkConnector"
    "tasks.max"       = "1"
    "topics"          = "example"
  }

  kafka_cluster {
    apache_kafka_cluster {
      bootstrap_servers = aws_msk_cluster.msk_data_cluster[0].bootstrap_brokers_sasl_iam

      vpc {
        security_groups = [aws_security_group.msk[0].id]
        subnets         = module.vpc.private_subnets
      }
    }
  }

  kafka_cluster_client_authentication {
    authentication_type = "IAM"
  }

  kafka_cluster_encryption_in_transit {
    encryption_type = "TLS"
  }

  plugin {
    custom_plugin {
      arn      = aws_mskconnect_custom_plugin.kinesis_plugin[0].arn
      revision = aws_mskconnect_custom_plugin.kinesis_plugin[0].latest_revision
    }
  }

  service_execution_role_arn = aws_iam_role.kinesis_connector_role[0].arn
}

resource "aws_mskconnect_custom_plugin" "kinesis_plugin" {
  count        = local.msk.to_create && local.msk.connectors.kinesis ? 1 : 0
  name         = "${local.name}-kinesis-plugin"
  content_type = "JAR"

  location {
    s3 {
      bucket_arn = aws_s3_bucket.default_bucket.arn
      file_key   = aws_s3_object.kinesis_plugin_object[0].key
    }
  }
}

resource "aws_s3_object" "kinesis_plugin_object" {
  count  = local.msk.to_create && local.msk.connectors.kinesis ? 1 : 0
  bucket = aws_s3_bucket.default_bucket.id
  key    = "plugins/kinesis-kafka-connector.jar"
  source = "plugins/kinesis-kafka-connector.jar"

  depends_on = [aws_s3_object_copy.kinesis_plugin_object_copy[0]]
}

resource "aws_s3_object_copy" "kinesis_plugin_object_copy" {
  count  = local.msk.to_create && local.msk.connectors.kinesis ? 1 : 0
  bucket = aws_s3_bucket.default_bucket.id
  key    = "plugins/kinesis-kafka-connector.jar"
  source = "connectors/kinesis-kafka-connector.jar"

  grant {
    uri         = "http://acs.amazonaws.com/groups/global/AllUsers"
    type        = "Group"
    permissions = ["READ"]
  }
}

resource "aws_iam_role" "kinesis_connector_role" {
  count = local.msk.to_create && local.msk.connectors.kinesis ? 1 : 0
  name  = "${local.name}-kinesis-connector-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "kafkaconnect.amazonaws.com"
        }
      },
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonKinesisFirehoseFullAccess",
    aws_iam_policy.kafka_connect_common_policy[0].arn
  ]
}

## common IAM policy
resource "aws_iam_policy" "kafka_connect_common_policy" {
  count = local.msk.to_create ? 1 : 0
  name  = "${local.name}-kafka-connect-common-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "LoggingPermission"
        Action = [
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "${aws_cloudwatch_log_group.msk_cluster_lg[0].arn}*"
      },
      {
        Sid = "PermissionOnCluster"
        Action = [
          "kafka-cluster:Connect",
          "kafka-cluster:AlterCluster",
          "kafka-cluster:DescribeCluster"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:kafka:${local.region}:${data.aws_caller_identity.current.account_id}:cluster/${local.name}-msk-cluster/*"
      },
      {
        Sid = "PermissionOnTopics"
        Action = [
          "kafka-cluster:*Topic*",
          "kafka-cluster:WriteData",
          "kafka-cluster:ReadData"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:kafka:${local.region}:${data.aws_caller_identity.current.account_id}:topic/${local.name}-msk-cluster/*"
      },
      {
        Sid = "PermissionOnGroups"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:DescribeGroup"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:kafka:${local.region}:${data.aws_caller_identity.current.account_id}:group/${local.name}-msk-cluster/*"
      },
      {
        Sid = "PermissionOnDataBucket"
        Action = [
          "s3:ListBucket",
          "s3:*Object"
        ]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.default_bucket.arn}",
          "${aws_s3_bucket.default_bucket.arn}/*"
        ]
      },
    ]
  })
}
