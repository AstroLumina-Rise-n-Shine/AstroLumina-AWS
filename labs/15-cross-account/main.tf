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
# This lab spans TWO accounts:
#   Account A = 111111111111 (owns the bucket and the cross-account role)
#   Account B = 222222222222 (owns a user allowed to assume that role)
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
    s3  = "http://localhost:4566"
    iam = "http://localhost:4566"
    sts = "http://localhost:4566"
  }
}

# Account B's static identity, used to create a user + access key there.
provider "aws" {
  alias      = "account_b"
  region     = "us-east-1"
  access_key = "222222222222"
  secret_key = "test"

  # Floci is not real AWS: skip anything that would reach real endpoints.
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    sts = "http://localhost:4566"
    iam = "http://localhost:4566"
    s3  = "http://localhost:4566"
  }
}

# Terraform itself proves the assume works: this provider starts from account
# B's static keys and assumes the role living in account A.
provider "aws" {
  alias      = "assumed_from_b"
  region     = "us-east-1"
  access_key = "222222222222"
  secret_key = "test"

  # Floci is not real AWS: skip anything that would reach real endpoints.
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  assume_role {
    role_arn     = "arn:aws:iam::111111111111:role/astrolumina-learning-cross-role"
    session_name = "astrolumina-learning"
    external_id  = "astrolumina-learning"
  }

  endpoints {
    sts = "http://localhost:4566"
    iam = "http://localhost:4566"
    s3  = "http://localhost:4566"
  }
}

# Proof: with the assumed_from_b provider, GetCallerIdentity must report
# account A (111111111111) even though the base credentials belong to account B.
data "aws_caller_identity" "assumed" {
  provider = aws.assumed_from_b
}

# ---- Account A: the data bucket -------------------------------------------
module "data_bucket" {
  source = "git::https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library.git//modules/aws_s3_bucket?ref=main"

  name               = "astrolumina-learning-cross-data"
  versioning_enabled = true

  environment = "learning"
  tags = {
    lab = "15-cross-account"
  }
}

# ---- Account A: the role account B is allowed to assume -------------------
module "cross_role" {
  source = "git::https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library.git//modules/aws_cross_account_role?ref=main"

  # The module names the IAM role exactly this (no prefix), which is why the
  # hardcoded role ARN in the assumed_from_b provider above matches it.
  name = "astrolumina-learning-cross-role"

  trusted_account_id = "222222222222"
  external_id        = "astrolumina-learning"

  # Least privilege inside the trust: only read/write the one data bucket
  # (reference the bucket module output so the ARN is always in sync).
  inline_policies = {
    "bucket-rw" = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid      = "ListBucket"
          Effect   = "Allow"
          Action   = ["s3:ListBucket"]
          Resource = [module.data_bucket.bucket_arn]
        },
        {
          Sid      = "ReadWriteObjects"
          Effect   = "Allow"
          Action   = ["s3:GetObject", "s3:PutObject"]
          Resource = ["${module.data_bucket.bucket_arn}/*"]
        }
      ]
    })
  }

  environment = "learning"
  tags = {
    lab = "15-cross-account"
  }
}

# ---- Account B: the user that runs the assuming --------------------------
module "account_b_user" {
  source = "git::https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library.git//modules/aws_iam_user?ref=main"

  # Route this module's resources into account B instead of the default provider.
  providers = { aws = aws.account_b }

  name              = "astrolumina-learning-account-b-app"
  create_access_key = true

  inline_policies = {
    "assume-role" = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid      = "AssumeCrossRole"
          Effect   = "Allow"
          Action   = ["sts:AssumeRole"]
          Resource = [module.cross_role.role_arn]
        }
      ]
    })
  }

  environment = "learning"
  tags = {
    lab = "15-cross-account"
  }
}
