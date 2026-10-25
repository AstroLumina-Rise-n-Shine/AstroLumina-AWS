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
    s3    = "http://localhost:4566"
    ec2   = "http://localhost:4566"
    elbv2 = "http://localhost:4566"
  }
}

# VPC with two public subnets across two AZs. An ALB must be attached to at
# least two subnets in different AZs, which is why the module call here never
# goes below two public subnets.
module "alb_net" {
  source = "git::https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library.git//modules/aws_network?ref=1.0.6"

  name                    = "astrolumina-learning-alb-net"
  cidr_block              = "10.47.0.0/16"
  availability_zones      = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs     = ["10.47.1.0/24", "10.47.2.0/24"]
  private_subnet_cidrs    = []
  enable_nat_gateway      = false # NAT is off: nothing lives in the private tier here
  map_public_ip_on_launch = false # no EC2/Fargate tasks in this lab yet, nothing needs public IPs

  environment = "learning"
  tags = {
    lab = "11-alb-ingress"
  }
}

# Security group attached to the ALB: world-readable HTTP on port 80 (this is a
# deliberately internet-facing lab), full egress so the ALB can reach targets.
resource "aws_security_group" "alb_sg" {
  name        = "astrolumina-learning-alb-sg"
  description = "HTTP ingress for the learning lab ALB"
  vpc_id      = module.alb_net.vpc_id

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
    Name = "astrolumina-learning-alb-sg"
    lab  = "11-alb-ingress"
  }
}

# ALB access logs require a destination bucket and a policy for the AWS log
# delivery service. This lab's Floci credentials map to account 111111111111.
resource "aws_s3_bucket" "alb_access_logs" {
  bucket        = "astrolumina-learning-alb-access-logs"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "alb_access_logs" {
  bucket = aws_s3_bucket.alb_access_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "alb_access_logs" {
  bucket = aws_s3_bucket.alb_access_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "alb_access_logs" {
  bucket = aws_s3_bucket.alb_access_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "alb_access_logs" {
  bucket = aws_s3_bucket.alb_access_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowALBLogDelivery"
      Effect    = "Allow"
      Principal = { Service = "logdelivery.elasticloadbalancing.amazonaws.com" }
      Action    = "s3:PutObject"
      Resource  = "${aws_s3_bucket.alb_access_logs.arn}/alb/AWSLogs/111111111111/*"
      Condition = {
        StringEquals = { "aws:SourceAccount" = "111111111111" }
      }
    }]
  })
}

# The ALB itself, with one HTTP listener on port 80 and an (empty for now)
# IP target group that health-checks "/".
module "alb" {
  source = "git::https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library.git//modules/aws_alb?ref=1.0.6"

  name               = "astrolumina-learning-alb"
  vpc_id             = module.alb_net.vpc_id
  subnet_ids         = module.alb_net.public_subnet_ids
  security_group_ids = [aws_security_group.alb_sg.id]
  access_logs_bucket = aws_s3_bucket.alb_access_logs.id
  access_logs_prefix = "alb"
  depends_on = [
    aws_s3_bucket_policy.alb_access_logs,
    aws_s3_bucket_public_access_block.alb_access_logs,
    aws_s3_bucket_server_side_encryption_configuration.alb_access_logs,
    aws_s3_bucket_versioning.alb_access_logs,
  ]

  # The module's secure default is internal = true (VPC-only). This lab
  # deliberately exposes the entry point to the internet, so it is flipped off.
  internal = false

  listener_protocol = "HTTP" # HTTPS would need an ACM certificate; the emulator has none
  listener_port     = 80

  target_port       = 80
  target_type       = "ip" # Fargate/awsvpc style targets; register EC2/aws_s3 later
  health_check_path = "/"

  environment = "learning"
  tags = {
    lab = "11-alb-ingress"
  }
}
