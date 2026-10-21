output "kms_key_arn" {
  description = "ARN of the customer-managed KMS key encrypting the CloudTrail logs"
  value       = module.security_baseline.kms_key_arn
}

output "kms_alias_name" {
  description = "Friendly alias name referring to the KMS key (starts with alias/)"
  value       = module.security_baseline.kms_alias_name
}

output "guardduty_detector_id" {
  description = "ID of the GuardDuty detector collecting threat findings"
  value       = module.security_baseline.guardduty_detector_id
}

output "cloudtrail_arn" {
  description = "ARN of the audit trail recording every API call"
  value       = module.security_baseline.cloudtrail_arn
}
