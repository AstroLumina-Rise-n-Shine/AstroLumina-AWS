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
    budgets = "http://localhost:4566"
    sns     = "http://localhost:4566"
    kms     = "http://localhost:4566"
  }
}

# A monthly cost budget of $50 that alerts a subscriber at 50%, 80% and 100%
# of the limit. Budgets notifications ride on SNS: the module creates the
# topic, subscribes the emails and wires the budget to publish there.
module "monthly_budget" {
  source = "git::https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library.git//modules/aws_budget?ref=main"

  name = "astrolumina-learning-budget-monthly"

  # A decimal string, because the budget API treats the amount as text.
  limit_amount = "50"
  time_unit    = "MONTHLY"
  budget_type  = "COST"

  # Alert at 50%, 80% and 100% of the limit.
  notification_thresholds = [50, 80, 100]

  # Placeholder address for learning. On real AWS each subscriber receives an
  # SNS confirmation email that must be clicked once before notifications flow.
  notification_emails = ["cost-alerts@example.com"]

  environment = "learning"
  tags = {
    lab = "14-budgets-cost"
  }
}
