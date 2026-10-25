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
    ecs = "http://localhost:4566"
    ec2 = "http://localhost:4566"
    iam = "http://localhost:4566"
  }
}

# Public subnets with auto-assigned public IPs so the Fargate task ENI can
# pull the image and be reachable without a NAT/load-balancer layer.
module "network" {
  source = "git::https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library.git//modules/aws_network?ref=1.0.6"

  name               = "astrolumina-learning-ecs-net"
  cidr_block         = "10.45.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]

  public_subnet_cidrs  = ["10.45.1.0/24", "10.45.2.0/24"]
  private_subnet_cidrs = []

  # Opt-in for this internet-facing lab (module default is false).
  map_public_ip_on_launch = true

  environment = "learning"

  tags = {
    lab = "08-ecs-fargate"
  }
}

# HTTP in from anywhere, all egress out (the task must pull images).
resource "aws_security_group" "web" {
  name        = "astrolumina-learning-ecs-sg"
  description = "HTTP access for the Fargate task"
  vpc_id      = module.network.vpc_id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
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
    Name        = "astrolumina-learning-ecs-sg"
    lab         = "08-ecs-fargate"
    environment = "learning"
  }
}

# One nginx:alpine task Floci runs as a real local container.
module "ecs" {
  source = "git::https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library.git//modules/aws_ecs_fargate?ref=1.0.6"

  name   = "astrolumina-learning-ecs"
  image  = "nginx:alpine"
  cpu    = "256" # Fargate CPU units, as a string
  memory = "512" # Fargate memory in MiB, as a string

  desired_count      = 1
  subnet_ids         = module.network.public_subnet_ids
  security_group_ids = [aws_security_group.web.id]
  container_port     = 80

  environment = "learning"

  tags = {
    lab = "08-ecs-fargate"
  }
}
