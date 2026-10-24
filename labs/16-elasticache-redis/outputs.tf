output "redis_endpoint_address" {
  description = "Primary endpoint hostname Redis clients connect to"
  value       = module.redis.primary_endpoint_address
}

output "redis_port" {
  description = "Port the Redis cache listens on"
  value       = module.redis.port
}

output "redis_security_group_id" {
  description = "Security group created for the cache"
  value       = module.redis.security_group_id
}

output "redis_replication_group_id" {
  description = "Identifier of the Redis replication group"
  value       = module.redis.id
}

output "redis_replication_group_arn" {
  description = "ARN of the Redis replication group"
  value       = module.redis.arn
}
