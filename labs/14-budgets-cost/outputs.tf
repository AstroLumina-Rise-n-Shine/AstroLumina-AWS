output "budget_name" {
  description = "Name of the created AWS Budget (check it in describe-budgets)"
  value       = module.monthly_budget.budget_name
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic the budget publishes alert notifications to"
  value       = module.monthly_budget.sns_topic_arn
}
