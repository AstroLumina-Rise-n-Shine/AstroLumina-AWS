output "zone_id" {
  description = "Hosted zone ID -- plug it into list-resource-record-sets when verifying"
  value       = module.dns_zone.zone_id
}

output "zone_name" {
  description = "Domain name of the hosted zone"
  value       = module.dns_zone.zone_name
}

output "name_servers" {
  description = "Authoritative name servers. On real AWS you would set these as NS records at your registrar; on Floci there is no registrar, so this is informational."
  value       = module.dns_zone.name_servers
}
