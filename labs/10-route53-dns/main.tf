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
    route53 = "http://localhost:4566"
  }
}

# One public hosted zone. The domain is a made-up convention TLD, so it never
# collides with anything real. The two A record IPs come from 192.0.2.0/24
# (TEST-NET-1, reserved for documentation) -- they cannot be routed anywhere.
module "dns_zone" {
  source = "git::https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library.git//modules/aws_route53_zone?ref=1.0.4"

  name = "astrolumina-learning.test"

  # Map shape (declared by the module):
  #   "<relative name>" => { type = string, ttl = number, values = list(string) }
  # "@" means the zone apex (astrolumina-learning.test itself).
  records = {
    "@" = {
      type   = "A"
      ttl    = 300
      values = ["192.0.2.10"]
    }
    "www" = {
      type   = "CNAME"
      ttl    = 300
      values = ["astrolumina-learning.test"]
    }
    "api" = {
      type   = "A"
      ttl    = 300
      values = ["192.0.2.11"]
    }
  }

  environment = "learning"
  tags = {
    lab = "10-route53-dns"
  }
}
