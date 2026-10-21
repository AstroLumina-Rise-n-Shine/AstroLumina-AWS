output "role_arn" {
  description = "ARN of the app role -- pass as the Trust anchor to services like Lambda"
  value       = module.app_role.role_arn
}

output "user_name" {
  description = "Name of the app IAM user"
  value       = module.app_user.user_name
}

output "access_key_id" {
  description = "Access key ID generated for the user"
  value       = module.app_user.access_key_id
}

output "secret_access_key" {
  description = "Secret access key of the user -- this is a Floci dummy, never reuse it on real AWS"
  value       = module.app_user.secret_access_key
  sensitive   = true
}
