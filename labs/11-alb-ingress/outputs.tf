output "alb_dns_name" {
  description = "Public DNS name of the ALB -- on a real deployment you would point your DNS at it (see lab 10)"
  value       = module.alb.alb_dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = module.alb.alb_arn
}

output "target_group_arn" {
  description = "ARN of the target group -- register targets (EC2 instances, IPs) into this to receive traffic"
  value       = module.alb.target_group_arn
}
