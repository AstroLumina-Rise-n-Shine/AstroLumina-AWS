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
    ec2 = "http://localhost:4566"
  }
}

# Network: VPC with an IGW, plus two public and two private subnets spread
# across two AZs. NAT is off by default in the module; flipping it on is a
# "try next" item — Floci NAT support unverified.
module "network" {
  source = "git::https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library.git//modules/aws_network?ref=1.0.6"

  name       = "astrolumina-learning-network"
  cidr_block = "10.42.0.0/16"

  availability_zones = ["us-east-1a", "us-east-1b"]

  public_subnet_cidrs  = ["10.42.1.0/24", "10.42.2.0/24"]
  private_subnet_cidrs = ["10.42.11.0/24", "10.42.12.0/24"]

  # NAT is off by default in the module; flipping it on is a "try next" item.
  enable_nat_gateway = false

  environment = "learning"

  tags = {
    lab = "04-vpc-network"
  }
}

# Security group in the new VPC: web tier ingress on 80 and 443 from anywhere,
# all egress allowed (stateful firewall returns traffic automatically).
resource "aws_security_group" "web" {
  name        = "astrolumina-learning-web-sg"
  description = "Web tier: HTTPS in from anywhere"
  vpc_id      = module.network.vpc_id

  ingress {
    description = "HTTP in from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS in from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "astrolumina-learning-web-sg"
    Environment = "learning"
    lab         = "04-vpc-network"
  }
}
