## data sources for general resources
# Find the user currently in use by AWS
data "aws_caller_identity" "current" {}

# Region in which to deploy the solution
data "aws_region" "current" {}

# Availability zones to use in our soultion
data "aws_availability_zones" "available" {
  state = "available"
}

## data sources for VPN
# Local ip address
data "http" "local_ip_address" {
  url = "https://ifconfig.me/ip"
}

# Latest Amazon linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}

data "aws_secretsmanager_secret" "vpn_secrets" {
  count = local.vpn.to_create ? 1 : 0
  name  = aws_secretsmanager_secret.vpn_secrets[0].name
}

data "aws_secretsmanager_secret_version" "vpn_secrets" {
  count     = local.vpn.to_create ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.vpn_secrets[0].id
}

## data sources for redshift integration
data "aws_lambda_function" "kafka_producer_lambda" {
  function_name = local.producer.function_name

  depends_on = [
    module.kafka_producer_lambda
  ]
}
