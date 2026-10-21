output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets (internet-facing tier)"
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets (internal tier)"
  value       = module.network.private_subnet_ids
}

output "security_group_id" {
  description = "ID of the web tier security group -- pass to EC2/ALB/ECS stacks"
  value       = aws_security_group.web.id
}
