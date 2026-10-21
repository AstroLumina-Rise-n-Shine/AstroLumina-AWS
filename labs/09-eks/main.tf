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
    eks = "http://localhost:4566"
    ec2 = "http://localhost:4566"
    iam = "http://localhost:4566"
    kms = "http://localhost:4566"
  }
}

# Public subnets with auto-assigned public IPs (hosting-lab layout).
module "network" {
  source = "git::https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library.git//modules/aws_network?ref=1.0.4"

  name               = "astrolumina-learning-eks-net"
  cidr_block         = "10.46.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]

  public_subnet_cidrs  = ["10.46.1.0/24", "10.46.2.0/24"]
  private_subnet_cidrs = []

  # Opt-in for this internet-facing lab (module default is false).
  map_public_ip_on_launch = true

  environment = "learning"

  tags = {
    lab = "09-eks"
  }
}

# This lab only needs the baseline's customer-managed KMS key so the EKS
# secrets envelope encryption has a key to point at; GuardDuty, Security Hub
# and CloudTrail are disabled on purpose (labs/12-security covers them in full).
module "kms_key" {
  source = "git::https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library.git//modules/aws_security_baseline?ref=1.0.4"

  name = "astrolumina-learning-eks-kms"

  # Terraform 1.9 does not short-circuit the module's `var == null ||
  # length(var)` validation, so the null defaults fail `validate` there.
  # These equal the module's derived defaults; CloudTrail stays disabled.
  cloudtrail_bucket_name             = "astrolumina-learning-eks-kms-cloudtrail"
  cloudtrail_access_logs_bucket_name = "astrolumina-learning-eks-kms-cloudtrail-access-logs"

  enable_guardduty    = false
  enable_security_hub = false
  enable_cloudtrail   = false

  environment = "learning"

  tags = {
    lab = "09-eks"
  }
}

# Real EKS (Floci runs it as a real k3s control plane): heaviest lab, hold on.
module "eks" {
  source = "git::https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library.git//modules/aws_eks?ref=1.0.4"

  name               = "astrolumina-learning"
  kubernetes_version = "1.29"
  subnet_ids         = module.network.public_subnet_ids

  # Secrets (Kubernetes Secrets API objects) are envelope-encrypted with CMK.
  cluster_encryption_key_arn = module.kms_key.kms_key_arn

  instance_types = ["t3.small"]
  desired_size   = 1
  min_size       = 1
  max_size       = 1

  environment = "learning"

  tags = {
    lab = "09-eks"
  }
}
