output "role_arn" {
  description = "ARN of the cross-account role in account A (the thing account B assumes)"
  value       = module.cross_role.role_arn
}

output "data_bucket_name" {
  description = "Name of the S3 bucket living in account A that the role may read/write"
  value       = module.data_bucket.bucket_id
}

output "account_b_user" {
  description = "Name of the IAM user created in account B with sts:AssumeRole permission"
  value       = module.account_b_user.user_name
}

output "assumed_account_id" {
  description = "Account ID reported by GetCallerIdentity through the assumed_from_b provider -- should be 111111111111 (account A), proving the assume-role chain works end to end"
  value       = data.aws_caller_identity.assumed.account_id
}
