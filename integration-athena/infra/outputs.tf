# VPC releated
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "nat_public_ips" {
  description = "List of public Elastic IPs created for AWS NAT Gateway"
  value       = module.vpc.nat_public_ips
}

output "azs" {
  description = "A list of availability zones specified as argument to this module"
  value       = module.vpc.azs
}

# default bucket
output "default_bucket_name" {
  description = "Default bucket name"
  value       = aws_s3_bucket.default_bucket.id
}

# VPN related
output "vpn_launch_template_arn" {
  description = "The ARN of the VPN launch template"
  value = {
    for k, v in module.vpn : k => v.launch_template_arn
  }
}

output "vpn_autoscaling_group_id" {
  description = "VPN autoscaling group id"
  value = {
    for k, v in module.vpn : k => v.autoscaling_group_id
  }
}

output "vpn_autoscaling_group_name" {
  description = "VPN autoscaling group name"
  value = {
    for k, v in module.vpn : k => v.autoscaling_group_name
  }
}

# MSK related
output "msk_arn" {
  description = "Amazon Resource Name (ARN) of the MSK cluster"
  value       = aws_msk_cluster.msk_data_cluster.arn
}

output "msk_bootstrap_brokers_sasl_iam" {
  description = "One or more DNS names (or IP addresses) and SASL IAM port pairs"
  value       = aws_msk_cluster.msk_data_cluster.bootstrap_brokers_sasl_iam
}

# Athena related
output "athena_connector_stack_id" {
  description = "Athena connector stack ID"
  value       = aws_serverlessapplicationrepository_cloudformation_stack.athena_msk_connector.id
}

output "athena_connector_stack_outputs" {
  description = "Athena connector stack outputs"
  value       = aws_serverlessapplicationrepository_cloudformation_stack.athena_msk_connector.outputs
}

output "athena_connector_role_arn" {
  description = "ARN of athena connector execution role"
  value       = aws_iam_role.athena_connector_role.arn
}

output "athena_connector_sg_id" {
  description = "Athena connector security group ID"
  value       = aws_security_group.athena_connector.id
}

output "aws_glue_registry_name" {
  description = "Glue schema registry name"
  value       = aws_glue_registry.msk_registry.registry_name
}

output "aws_glue_schema_name" {
  description = "Glue schema name"
  value       = aws_glue_schema.msk_schema.schema_name
}
