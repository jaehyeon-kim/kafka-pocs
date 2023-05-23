resource "aws_kinesis_firehose_delivery_stream" "delivery_stream" {
  count       = local.firehose.to_create ? 1 : 0
  name        = "${local.name}-delivery-stream"
  destination = "redshift"

  s3_configuration {
    role_arn           = aws_iam_role.firehose_role[0].arn
    bucket_arn         = aws_s3_bucket.default_bucket.arn
    buffer_size        = 10
    buffer_interval    = 400
    compression_format = "GZIP"
  }

  redshift_configuration {
    role_arn        = aws_iam_role.firehose_role[0].arn
    cluster_jdbcurl = "jdbc:redshift://${aws_redshiftserverless_workgroup.workgroup.endpoint}/${local.redshift.db_name}"
    username        = local.redshift.admin_username
    password        = random_password.redshift_admin_pw.result
    data_table_name = local.redshift.table_name
    copy_options    = "delimiter '|'" # the default delimiter
    s3_backup_mode  = "Enabled"

    s3_backup_configuration {
      role_arn           = aws_iam_role.firehose_role[0].arn
      bucket_arn         = aws_s3_bucket.default_bucket.arn
      buffer_size        = 15
      buffer_interval    = 300
      compression_format = "GZIP"
    }
  }
}

# iam role
resource "aws_iam_role" "firehose_role" {
  count = local.firehose.to_create ? 1 : 0
  name  = "${local.name}-delivery-stream-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "firehose.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = "${local.name}-firehose-permission"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid = "PermissionOnS3"
          Action = [
            "s3:AbortMultipartUpload",
            "s3:GetBucketLocation",
            "s3:GetObject",
            "s3:ListBucket",
            "s3:ListBucketMultipartUploads",
            "s3:PutObject"
          ]
          Effect = "Allow"
          Resource = [
            "${aws_s3_bucket.default_bucket.arn}",
            "${aws_s3_bucket.default_bucket.arn}/*"
          ]
        },
        {
          Sid = "PermissionOnLogGroup"
          Action = [
            "logs:PutLogEvents"
          ]
          Effect   = "Allow"
          Resource = "${aws_cloudwatch_log_group.firehose_lg[0].arn}:*"
        }
      ]
    })
  }
}

resource "aws_cloudwatch_log_group" "firehose_lg" {
  count = local.firehose.to_create ? 1 : 0
  name  = "/${local.name}/firehose"

  retention_in_days = 1

  tags = local.tags
}
