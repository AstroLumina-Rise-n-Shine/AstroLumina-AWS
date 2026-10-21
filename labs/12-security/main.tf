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
    kms         = "http://localhost:4566"
    guardduty   = "http://localhost:4566"
    securityhub = "http://localhost:4566"
    cloudtrail  = "http://localhost:4566"
    s3          = "http://localhost:4566"
    iam         = "http://localhost:4566"
  }
}

# The security baseline at its defaults: a customer-managed KMS key (+ alias),
# a GuardDuty detector and a CloudTrail trail with CMK encryption + log file
# validation, writing to its own trail S3 bucket. Every toggle
# (enable_guardduty / enable_security_hub / enable_cloudtrail) defaults to true
# on purpose -- you switch things OFF explicitly when the sandbox does not
# need them, never silently. Here Security Hub is switched off: the Floci
# emulator cannot disable it once enabled, so the provider resource cannot
# round-trip (see the module call).
module "security_baseline" {
  source = "git::https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library.git//modules/aws_security_baseline?ref=1.0.4"

  name = "astrolumina-learning-security" # also prefixes the KMS alias and defaults the trail bucket name

  # Floci limitation: Security Hub can be ENABLED through the API but the
  # emulator cannot disable it again, so EnableSecurityHub starts answering
  # "already enabled" and the provider's account resource cannot round-trip.
  # The lab therefore leaves Security Hub out of Terraform state; on real AWS
  # flip this to true. The rest of the baseline (KMS, GuardDuty, CloudTrail)
  # is managed normally.
  enable_security_hub = false

  environment = "learning"
  tags = {
    lab = "12-security"
  }
}
