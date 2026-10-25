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
    rds = "http://localhost:4566"
    ec2 = "http://localhost:4566"
  }
}

# Network: two private subnets in different AZs — the minimum RDS subnet
# group layout. No public subnets: databases should never be internet-facing.
module "network" {
  source = "git::https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library.git//modules/aws_network?ref=1.0.6"

  name               = "astrolumina-learning-rds-net"
  cidr_block         = "10.44.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]

  public_subnet_cidrs  = []
  private_subnet_cidrs = ["10.44.11.0/24", "10.44.12.0/24"]

  environment = "learning"

  tags = {
    lab = "07-rds"
  }
}

# Postgres port 5432 reachable only from inside the lab VPC — never from
# 0.0.0.0/0. In real AWS you would narrow this to the app's SG or CIDR.
resource "aws_security_group" "db" {
  name        = "astrolumina-learning-db-sg"
  description = "Postgres access from the lab VPC only"
  vpc_id      = module.network.vpc_id

  ingress {
    description = "PostgreSQL from VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.44.0.0/16"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "astrolumina-learning-db-sg"
    lab         = "07-rds"
    environment = "learning"
  }
}

# A small managed Postgres instance Floci boots as a real container.
# NOTE: password "floci-learning-password" is a dummy for the emulator —
# never a real secret; on real AWS it would come from tfvars/secret store.
module "db" {
  source = "git::https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library.git//modules/aws_rds?ref=1.0.6"

  name           = "astrolumina-learning-db"
  engine         = "postgres"
  instance_class = "db.t3.micro"
  db_name        = "astrolumina"
  username       = "astrolumina"
  password       = "floci-learning-password" # dummy for the emulator, never a real secret

  subnet_ids         = module.network.private_subnet_ids
  security_group_ids = [aws_security_group.db.id]

  publicly_accessible = false
  deletion_protection = false # lab override so destroy stays one command
  skip_final_snapshot = true

  environment = "learning"

  tags = {
    lab = "07-rds"
  }
}
