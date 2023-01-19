output "kafka_producer_function_name" {
  description = "The ARN of the Lambda Function"
  value       = module.kafka_producer.lambda_function_name
}
