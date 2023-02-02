# kafka producer outputs
output "kafka_producer_function_name" {
  description = "The ARN of the Lambda Function"
  value       = module.kafka_producer_lambda.lambda_function_name
}
