locals {
  name        = basename(path.cwd) == "infra" ? basename(dirname(path.cwd)) : basename(path.cwd)
  region      = data.aws_region.current.name
  environment = "dev"

  vpc = {
    cidr = "10.0.0.0/16"
    azs  = slice(data.aws_availability_zones.available.names, 0, 3)
  }

  default_bucket = {
    to_update_acl = false
    name          = "${local.name}-${data.aws_caller_identity.current.account_id}-${local.region}"
  }

  vpn = {
    to_create    = false
    to_use_spot  = false
    ingress_cidr = "${data.http.local_ip_address.response_body}/32"
    spot_override = [
      { instance_type : "t3.nano" },
      { instance_type : "t3a.nano" },
    ]
  }

  msk = {
    to_create        = false
    version          = "2.8.1"
    instance_size    = "kafka.m5.large"
    ebs_volume_size  = 20
    log_retention_ms = 604800000 # 7 days
    connectors = {
      datagen = false
      kinesis = false
      camel   = false
    }
  }

  redshift = {
    node_type           = "dc2.large" # ra3.xlplus, ra3.4xlplus, ra3.16xlplus
    number_of_nodes     = 2
    port_number         = 5439
    admin_username      = "master"
    db_name             = "main"
    table_name          = "orders"
    publicly_accessible = local.firehose.to_create
  }

  redshift_serverless = {
    base_capacity       = 128
    admin_username      = "master"
    db_name             = "main"
    table_name          = "orders"
    publicly_accessible = local.firehose.to_create
  }

  firehose = {
    to_create  = true
    cidr_block = "13.210.67.224/27"
  }

  tags = {
    Name        = local.name
    Environment = local.environment
  }
}
