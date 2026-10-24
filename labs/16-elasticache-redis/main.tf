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
    elasticache = "http://localhost:4566"
    ec2         = "http://localhost:4566"
  }
}

# Network: two private subnets in different AZs — the minimum ElastiCache
# subnet group layout. No public subnets: caches should never be
# internet-facing.
module "network" {
  source = "git::https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library.git//modules/aws_network?ref=1.0.5"

  name               = "astrolumina-learning-elasticache-net"
  cidr_block         = "10.47.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]

  public_subnet_cidrs  = []
  private_subnet_cidrs = ["10.47.11.0/24", "10.47.12.0/24"]

  environment = "learning"

  tags = {
    lab = "16-elasticache-redis"
  }
}

# A single-node managed Redis cache. The module's security group starts with
# no ingress rules; port 6379 is opened only to the lab VPC CIDR. At-rest and
# transit encryption keep the module defaults (both on).
module "redis" {
  source = "git::https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library.git//modules/aws_elasticache_redis?ref=1.0.5"

  name = "astrolumina-learning-cache"

  node_type = "cache.t3.micro"
  port      = 6379

  subnet_ids = module.network.private_subnet_ids
  vpc_id     = module.network.vpc_id

  create_security_group = true
  allowed_cidr_blocks   = ["10.47.0.0/16"]

  environment = "learning"

  tags = {
    lab = "16-elasticache-redis"
  }
}
