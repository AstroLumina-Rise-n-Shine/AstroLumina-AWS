output "vpn_connection_id" {
  description = "ID of the IPsec VPN connection (two tunnels)"
  value       = module.vpn.vpn_connection_id
}

output "vpn_gateway_id" {
  description = "ID of the VPN gateway attached to the VPC (the cloud side)"
  value       = module.vpn.vpn_gateway_id
}

output "customer_gateway_id" {
  description = "ID of the customer gateway (the on-prem side object, registered by public IP + ASN)"
  value       = module.vpn.customer_gateway_id
}

output "tunnel1_address" {
  description = "Public IP of the first VPN tunnel endpoint -- configure it on the on-prem device"
  value       = module.vpn.tunnel1_address
}

output "tunnel2_address" {
  description = "Public IP of the second (redundant) VPN tunnel endpoint"
  value       = module.vpn.tunnel2_address
}
