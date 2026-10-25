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

# Network: minimal two-tier setup with a single public subnet. Auto-assigning
# public IPs in public subnets is off by default in the module (secure
# default); we opt in explicitly because this lab is internet-facing.
module "network" {
  source = "git::https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library.git//modules/aws_network?ref=1.0.6"

  name       = "astrolumina-learning-ec2-net"
  cidr_block = "10.43.0.0/16"

  availability_zones = ["us-east-1a"]

  public_subnet_cidrs  = ["10.43.1.0/24"]
  private_subnet_cidrs = []

  # Opt-in for this internet-facing lab: instances in the public subnet get a
  # public IP on launch.
  map_public_ip_on_launch = true

  environment = "learning"

  tags = {
    lab = "05-ec2"
  }
}

# Security group letting you reach the box over SSH and plain HTTP.
resource "aws_security_group" "web" {
  name        = "astrolumina-learning-ec2-sg"
  description = "EC2 lab: SSH and HTTP in from anywhere"
  vpc_id      = module.network.vpc_id

  ingress {
    description = "SSH in from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP in from anywhere"
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
    Name        = "astrolumina-learning-ec2-sg"
    Environment = "learning"
    lab         = "05-ec2"
  }
}

# Instance: launched into the first public subnet via the module output, with
# a user_data script that runs on first boot.
module "web" {
  source = "git::https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library.git//modules/aws_ec2_instance?ref=1.0.6"

  name          = "astrolumina-learning-web-01"
  ami           = "ami-ubuntu2404-amd64"
  instance_type = "t3.micro"

  subnet_id          = module.network.public_subnet_ids[0]
  security_group_ids = [aws_security_group.web.id]

  user_data = <<-EOF
    #!/bin/bash
    echo "Hello from Floci" > /etc/motd
  EOF

  environment = "learning"

  tags = {
    lab = "05-ec2"
  }
}
