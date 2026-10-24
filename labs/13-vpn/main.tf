terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Floci emulator: dummy credentials. Account A = 111111111111; Floci treats an
# access key of exactly 12 digits as the account ID.
#
# NOTE: this lab is PLAN-ONLY against Floci. The emulator does not implement
# the site-to-site VPN APIs yet (they return UnsupportedOperation), so
# `terraform apply` would target real AWS. See the README.
provider "aws" {
  region     = "us-east-1"
  access_key = "111111111111"
  secret_key = "test"

  # Floci is not real AWS: skip anything that would reach real endpoints.
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  # Only the services this lab touches need an endpoint override.
  endpoints {
    ec2 = "http://localhost:4566"
  }
}

# The cloud side of the VPN: a VPC with one public subnet where the VPN
# gateway attaches logically.
module "vpn_net" {
  source = "git::https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library.git//modules/aws_network?ref=1.0.5"

  name                 = "astrolumina-learning-vpn-net"
  cidr_block           = "10.48.0.0/16"
  availability_zones   = ["us-east-1a"]
  public_subnet_cidrs  = ["10.48.1.0/24"]
  private_subnet_cidrs = []

  environment = "learning"
  tags = {
    lab = "13-vpn"
  }
}

# The VPN itself: three objects on the AWS side (customer gateway, VPN gateway,
# VPN connection with two IPsec tunnels) plus static routes pointing at your
# on-premises networks.
module "vpn" {
  source = "git::https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library.git//modules/aws_vpn?ref=1.0.5"

  name = "astrolumina-learning-vpn"

  vpc_id = module.vpn_net.vpc_id

  # Public IP of the "on-prem" router. 203.0.113.10 comes from TEST-NET-3
  # (RFC 5737, reserved for documentation) -- it cannot be routed anywhere.
  customer_gateway_ip = "203.0.113.10"

  # BGP ASN of the on-prem device. Kept as a string because the API expects it
  # that way. 65000 lives in the private ASN range, perfect for the lab.
  bgp_asn = "65000"

  # On-prem CIDRs routed through the VPN (static routes; the module sets
  # static_routes_only = true by default).
  destination_cidrs = ["192.168.0.0/16"]

  environment = "learning"
  tags = {
    lab = "13-vpn"
  }
}
