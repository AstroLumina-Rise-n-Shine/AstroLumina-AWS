# Phase 2 of lab 15: prove the cross-account assume with Terraform itself.
#
# Run this only AFTER the main config in ../ has been applied -- account A's
# role must already exist, because a provider cannot assume a role that the
# same apply is still about to create. This is a data-only config: it reads
# GetCallerIdentity through a session obtained by assuming account A's role
# with account B's static keys. Output assumed_account_id == 111111111111
# (account A) is the proof that the cross-account chain works.

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
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

data "aws_caller_identity" "assumed" {}

output "assumed_account_id" {
  description = "Account ID reported through the assumed session -- must be 111111111111 (account A), not the base identity's 222222222222"
  value       = data.aws_caller_identity.assumed.account_id
}
