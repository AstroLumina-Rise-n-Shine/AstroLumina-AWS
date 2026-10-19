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
    iam = "http://localhost:4566"
  }
}

# Role: trust policy lets the Lambda service assume it (the same setup a real
# Lambda function needs), with an AWS-managed logging policy plus a least-
# privilege inline policy granting only s3:GetObject.
module "app_role" {
  source = "git::https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library.git//modules/aws_iam_role?ref=main"

  name = "astrolumina-learning-app-role"

  assume_role_service = "lambda.amazonaws.com"

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
  ]

  inline_policies = {
    "s3-read" = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = ["s3:GetObject"]
          Resource = ["*"]
        },
      ]
    })
  }

  environment = "learning"

  tags = {
    lab = "03-iam"
  }
}

# User: human/programmatic identity with its own access key and the read-only
# AWS-managed policy attached.
module "app_user" {
  source = "git::https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library.git//modules/aws_iam_user?ref=main"

  name = "astrolumina-learning-app-user"

  create_access_key = true

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/ReadOnlyAccess",
  ]

  environment = "learning"

  tags = {
    lab = "03-iam"
  }
}
