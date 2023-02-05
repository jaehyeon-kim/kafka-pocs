output "kafka_producer_function_name" {
  description = "ARN of the Lambda Function"
  value       = module.kafka_producer_lambda.lambda_function_name
}

output "eventbridge_rule_ids" {
  description = "Eventbridge rule IDs"
  value       = module.eventbridge.eventbridge_rule_ids
}

output "vpc_id" {
  description = "VPC ID"
  value       = data.aws_vpc.selected.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = data.aws_subnets.private.ids
}

output "security_group_id" {
  description = "Security group ID"
  value       = data.aws_security_group.kafka_producer_lambda.id
}

output "bootstrap_servers" {
  description = "Bootstrap server addresses"
  value       = data.aws_msk_cluster.msk_data_cluster.bootstrap_brokers_sasl_iam
}
