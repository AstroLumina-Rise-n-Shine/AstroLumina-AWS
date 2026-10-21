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
    s3 = "http://localhost:4566"
  }
}

# Bucket: fixed name, no random suffix, fixed size for a learning lab.
# Versioning on so you can overwrite hello.txt later and still see old versions.
# AES256 is Amazon S3-managed server-side encryption (no KMS key needed here).
module "s3_bucket" {
  source = "git::https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library.git//modules/aws_s3_bucket?ref=1.0.4"

  name               = "astrolumina-learning-s3-data"
  versioning_enabled = true
  sse_algorithm      = "AES256"

  environment = "learning"

  tags = {
    lab = "01-s3"
  }
}

# Upload an object directly. Bucket is referenced via the module output instead
# of a hardcoded string -- this is how real stacks chain resources together.
resource "aws_s3_object" "hello" {
  bucket       = module.s3_bucket.bucket_id
  key          = "hello.txt"
  content      = "Hello from Terraform + Floci"
  content_type = "text/plain"
}
