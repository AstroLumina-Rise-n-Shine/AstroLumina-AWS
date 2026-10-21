output "function_name" {
  description = "Name of the deployed Lambda function"
  value       = module.hello_lambda.function_name
}

output "function_arn" {
  description = "ARN of the deployed Lambda function"
  value       = module.hello_lambda.function_arn
}
