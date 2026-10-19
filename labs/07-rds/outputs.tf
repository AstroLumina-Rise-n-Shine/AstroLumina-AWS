output "db_instance_address" {
  description = "Connection hostname (endpoint) of the database"
  value       = module.db.db_instance_address
}

output "db_instance_port" {
  description = "Port the database listens on"
  value       = module.db.db_instance_port
}

output "db_name" {
  description = "Name of the initial database inside the instance"
  value       = module.db.db_name
}
