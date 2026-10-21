terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
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
    lambda = "http://localhost:4566"
    iam    = "http://localhost:4566"
  }
}

# Zip up the Python handler so it can be deployed as a Lambda package.
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/src/handler.py"
  output_path = "${path.module}/handler.zip"
}

# Execution role Lambda assumes while running: basic logging via CloudWatch.
module "lambda_role" {
  source = "git::https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library.git//modules/aws_iam_role?ref=1.0.4"

  name                = "astrolumina-learning-lambda-role"
  assume_role_service = "lambda.amazonaws.com"

  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]

  environment = "learning"

  tags = {
    lab = "06-lambda"
  }
}

# The function itself: small Python 3.12 handler with one environment variable.
module "hello_lambda" {
  source = "git::https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library.git//modules/aws_lambda_function?ref=1.0.4"

  name             = "astrolumina-learning-hello"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  handler          = "handler.handler"
  runtime          = "python3.12"
  role_arn         = module.lambda_role.role_arn

  environment_variables = {
    GREETING = "Hello from Floci Lambda"
  }

  environment = "learning"

  tags = {
    lab = "06-lambda"
  }
}
