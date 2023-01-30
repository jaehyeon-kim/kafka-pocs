variable "vpn_to_create" {
  description = "Flag to indicate whether to create VPN"
  type        = bool
  default     = true
}

variable "vpn_to_use_spot" {
  description = "Flag to indicate whether to use a spot instance for VPN"
  type        = bool
  default     = false
}

variable "vpn_to_limit_vpn_ingress" {
  description = "Flag to indicate whether to limit ingress from the current machine's IP address"
  type        = bool
  default     = true
}

locals {
  name        = basename(path.cwd) == "infra" ? basename(dirname(path.cwd)) : basename(path.cwd)
  region      = data.aws_region.current.name
  environment = "dev"

  vpc = {
    cidr = "10.0.0.0/16"
    azs  = slice(data.aws_availability_zones.available.names, 0, 3)
  }

  default_bucket = {
    name = "${local.name}-${data.aws_caller_identity.current.account_id}-${local.region}"
  }

  vpn = {
    to_create    = var.vpn_to_create
    to_use_spot  = var.vpn_to_use_spot
    ingress_cidr = var.vpn_to_limit_vpn_ingress ? "${chomp(data.http.local_ip_address.response_body)}/32" : "0.0.0.0/0"
    spot_override = [
      { instance_type : "t3.nano" },
      { instance_type : "t3a.nano" },
    ]
  }

  redshift = {
    base_capacity  = 128
    admin_username = "master"
    db_name        = "main"
  }

  producer = {
    parent_path   = "${abspath(path.module)}/lambdas"
    function_name = "kafka_producer"
    handler       = "app.lambda_function"
    concurrency   = 2
    timeout       = 90
    memory_size   = 256
    runtime       = "python3.8"
    schedule_rate = "rate(1 minute)"
  }

  tags = {
    Name        = local.name
    Environment = local.environment
  }
}