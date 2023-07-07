## connectors
# camel dynamodb sink
resource "aws_mskconnect_connector" "camel_ddb_sink" {
  name = "${local.name}-order-sink"

  kafkaconnect_version = "2.7.1"

  capacity {
    provisioned_capacity {
      mcu_count    = 1
      worker_count = 1
    }
  }

  connector_configuration = {
    # connector configuration
    "connector.class"                = "org.apache.camel.kafkaconnector.awsddbsink.CamelAwsddbsinkSinkConnector",
    "tasks.max"                      = "1",
    "key.converter"                  = "org.apache.kafka.connect.storage.StringConverter",
    "key.converter.schemas.enable"   = false,
    "value.converter"                = "org.apache.kafka.connect.json.JsonConverter",
    "value.converter.schemas.enable" = false,
    # camel ddb sink configuration
    "topics"                                                   = "order",
    "camel.kamelet.aws-ddb-sink.table"                         = aws_dynamodb_table.orders_table.id,
    "camel.kamelet.aws-ddb-sink.region"                        = local.region,
    "camel.kamelet.aws-ddb-sink.operation"                     = "PutItem",
    "camel.kamelet.aws-ddb-sink.writeCapacity"                 = 1,
    "camel.kamelet.aws-ddb-sink.useDefaultCredentialsProvider" = true,
    "camel.sink.unmarshal"                                     = "jackson",
    # single message transforms
    "transforms"                          = "insertTS,formatTS",
    "transforms.insertTS.type"            = "org.apache.kafka.connect.transforms.InsertField$Value",
    "transforms.insertTS.timestamp.field" = "ordered_at",
    "transforms.formatTS.type"            = "org.apache.kafka.connect.transforms.TimestampConverter$Value",
    "transforms.formatTS.format"          = "yyyy-MM-dd HH:mm:ss:SSS",
    "transforms.formatTS.field"           = "ordered_at",
    "transforms.formatTS.target.type"     = "string"
  }

  kafka_cluster {
    apache_kafka_cluster {
      bootstrap_servers = aws_msk_cluster.msk_data_cluster.bootstrap_brokers_sasl_iam

      vpc {
        security_groups = [aws_security_group.msk.id]
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
      arn      = aws_mskconnect_custom_plugin.camel_ddb_sink.arn
      revision = aws_mskconnect_custom_plugin.camel_ddb_sink.latest_revision
    }
  }

  log_delivery {
    worker_log_delivery {
      cloudwatch_logs {
        enabled   = true
        log_group = aws_cloudwatch_log_group.camel_ddb_sink.name
      }
      s3 {
        enabled = true
        bucket  = aws_s3_bucket.default_bucket.id
        prefix  = "logs/msk/connect/camel-ddb-sink"
      }
    }
  }

  service_execution_role_arn = aws_iam_role.kafka_connector_role.arn

  depends_on = [
    aws_mskconnect_connector.msk_data_generator
  ]
}

resource "aws_mskconnect_custom_plugin" "camel_ddb_sink" {
  name         = "${local.name}-camel-ddb-sink"
  content_type = "ZIP"

  location {
    s3 {
      bucket_arn = aws_s3_bucket.default_bucket.arn
      file_key   = aws_s3_object.camel_ddb_sink.key
    }
  }
}

resource "aws_s3_object" "camel_ddb_sink" {
  bucket = aws_s3_bucket.default_bucket.id
  key    = "plugins/camel-aws-ddb-sink-kafka-connector.zip"
  source = "connectors/camel-aws-ddb-sink-kafka-connector.zip"

  etag = filemd5("connectors/camel-aws-ddb-sink-kafka-connector.zip")
}

resource "aws_cloudwatch_log_group" "camel_ddb_sink" {
  name = "/msk/connect/camel-ddb-sink"

  retention_in_days = 1

  tags = local.tags
}

# msk data generator
resource "aws_mskconnect_connector" "msk_data_generator" {
  name = "${local.name}-order-source"

  kafkaconnect_version = "2.7.1"

  capacity {
    provisioned_capacity {
      mcu_count    = 1
      worker_count = 1
    }
  }

  connector_configuration = {
    # connector configuration
    "connector.class"                = "com.amazonaws.mskdatagen.GeneratorSourceConnector",
    "tasks.max"                      = "1",
    "key.converter"                  = "org.apache.kafka.connect.storage.StringConverter",
    "key.converter.schemas.enable"   = false,
    "value.converter"                = "org.apache.kafka.connect.json.JsonConverter",
    "value.converter.schemas.enable" = false,
    # msk data generator configuration
    "genkp.order.with"              = "to-replace",
    "genv.order.order_id.with"      = "#{Internet.uuid}",
    "genv.order.product_id.with"    = "#{Code.isbn10}",
    "genv.order.quantity.with"      = "#{number.number_between '1','5'}",
    "genv.order.customer_id.with"   = "#{number.number_between '100','199'}",
    "genv.order.customer_name.with" = "#{Name.full_name}",
    "global.throttle.ms"            = "500",
    "global.history.records.max"    = "1000",
    # single message transforms
    "transforms"                            = "copyIdToKey,extractKeyFromStruct,cast",
    "transforms.copyIdToKey.type"           = "org.apache.kafka.connect.transforms.ValueToKey",
    "transforms.copyIdToKey.fields"         = "order_id",
    "transforms.extractKeyFromStruct.type"  = "org.apache.kafka.connect.transforms.ExtractField$Key",
    "transforms.extractKeyFromStruct.field" = "order_id",
    "transforms.cast.type"                  = "org.apache.kafka.connect.transforms.Cast$Value",
    "transforms.cast.spec"                  = "quantity:int8"
  }

  kafka_cluster {
    apache_kafka_cluster {
      bootstrap_servers = aws_msk_cluster.msk_data_cluster.bootstrap_brokers_sasl_iam

      vpc {
        security_groups = [aws_security_group.msk.id]
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
      arn      = aws_mskconnect_custom_plugin.msk_data_generator.arn
      revision = aws_mskconnect_custom_plugin.msk_data_generator.latest_revision
    }
  }

  log_delivery {
    worker_log_delivery {
      cloudwatch_logs {
        enabled   = true
        log_group = aws_cloudwatch_log_group.msk_data_generator.name
      }
      s3 {
        enabled = true
        bucket  = aws_s3_bucket.default_bucket.id
        prefix  = "logs/msk/connect/msk-data-generator"
      }
    }
  }

  service_execution_role_arn = aws_iam_role.kafka_connector_role.arn
}

resource "aws_mskconnect_custom_plugin" "msk_data_generator" {
  name         = "${local.name}-msk-data-generator"
  content_type = "JAR"

  location {
    s3 {
      bucket_arn = aws_s3_bucket.default_bucket.arn
      file_key   = aws_s3_object.msk_data_generator.key
    }
  }
}

resource "aws_s3_object" "msk_data_generator" {
  bucket = aws_s3_bucket.default_bucket.id
  key    = "plugins/msk-data-generator.jar"
  source = "connectors/msk-data-generator.jar"

  etag = filemd5("connectors/msk-data-generator.jar")
}

resource "aws_cloudwatch_log_group" "msk_data_generator" {
  name = "/msk/connect/msk-data-generator"

  retention_in_days = 1

  tags = local.tags
}

## IAM permission
resource "aws_iam_role" "kafka_connector_role" {
  name = "${local.name}-connector-role"

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
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
    aws_iam_policy.kafka_connector_policy.arn
  ]
}

resource "aws_iam_policy" "kafka_connector_policy" {
  name = "${local.name}-connector-policy"

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
      {
        Sid = "LoggingPermission"
        Action = [
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}
