output "instance_id" {
  description = "ID of the EC2 instance (i-...)"
  value       = module.web.instance_id
}

output "public_ip" {
  description = "Public IP assigned by the public subnet / Floci runtime"
  value       = module.web.public_ip
}

output "private_ip" {
  description = "Private IP inside the subnet"
  value       = module.web.private_ip
}
