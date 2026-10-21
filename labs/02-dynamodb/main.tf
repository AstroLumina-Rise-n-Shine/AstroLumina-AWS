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
    dynamodb = "http://localhost:4566"
  }
}

# Table: fixed name, composite key (string partition key + numeric sort key)
# and PAY_PER_REQUEST billing, which on real AWS means no capacity planning.
module "dynamodb_table" {
  source = "git::https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library.git//modules/aws_dynamodb_table?ref=1.0.4"

  name           = "astrolumina-learning-dynamodb"
  hash_key       = "pk" # partition key, attribute name
  hash_key_type  = "S"  # S = string
  range_key      = "sk" # optional sort key, attribute name
  range_key_type = "N"  # N = number (good for versions/epochs)
  billing_mode   = "PAY_PER_REQUEST"

  environment = "learning"

  tags = {
    lab = "02-dynamodb"
  }
}

# Seed two items. On DynamoDB, row identity = (hash_key, range_key); extra
# attributes ride along and are type-inferred from the JSON we encode.
resource "aws_dynamodb_table_item" "row_one" {
  table_name = module.dynamodb_table.table_name
  hash_key   = "pk"
  range_key  = "sk"

  # DynamoDB item JSON is typed: {"S": "..."} for strings, {"N": "..."} for
  # numbers. A plain map is rejected -- every attribute carries its type tag.
  item = jsonencode({
    pk   = { S = "user#1" }
    sk   = { N = "1" }
    note = { S = "first row" }
  })
}

resource "aws_dynamodb_table_item" "row_two" {
  table_name = module.dynamodb_table.table_name
  hash_key   = "pk"
  range_key  = "sk"

  # Same typed-JSON shape as row_one; only the sort key differs.
  item = jsonencode({
    pk   = { S = "user#1" }
    sk   = { N = "2" }
    note = { S = "second row" }
  })
}
