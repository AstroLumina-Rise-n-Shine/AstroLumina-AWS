output "table_name" {
  description = "Name of the created DynamoDB table"
  value       = module.dynamodb_table.table_name
}

output "table_arn" {
  description = "ARN of the table -- useful for IAM policy references"
  value       = module.dynamodb_table.table_arn
}
