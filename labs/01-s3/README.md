# 01 — Object storage (S3)

This lab deploys your first piece of real infrastructure through Terraform: an S3
bucket with versioning and encryption enabled, plus one object uploaded into it.
Everything lands on the local Floci emulator, so you can apply, inspect and
destroy as often as you like — no AWS account, no cost.

## What you'll learn

- Declaring a **provider block** pinned to a specific region (here: Floci's fake local AWS)
- Calling a reusable **module** and passing `environment` + `tags` down to it
- Referencing a resource created by a module through its **outputs**
- Uploading an **object** (`aws_s3_object`) with content and content type

## Resources created

- S3 bucket `astrolumina-learning-s3-data` — versioning enabled, AES256 server-side encryption, tags `Environment=learning`, `lab=01-s3`
- S3 object `hello.txt` with the content `Hello from Terraform + Floci`

## Run it

```bash
cd labs/01-s3
terraform init
terraform apply
```

## Verify

One-time environment setup (dummy Floci credentials, region, and endpoint):

```bash
export AWS_ACCESS_KEY_ID=111111111111 AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1 AWS_ENDPOINT_URL=http://localhost:4566
```

List your buckets, then stream the object's content back:

```bash
aws s3 ls
aws s3 cp s3://astrolumina-learning-s3-data/hello.txt -
```

Overwrite the object and re-run the `aws s3 cp` — versioning means both
versions are kept. Also check the Floci dashboard at http://localhost:8080 and
click through to **S3** to see the same bucket visually.

## Destroy

```bash
terraform destroy
```

## Try next

- Add a second object with a larger `content` and enable bucket-inventory-style prefixes (e.g. `logs/`, `data/`) to organize keys
- Point the `sse_algorithm` at `aws:kms` by adding `labs/12-security`'s KMS key to this lab
- Change `versioning_enabled` to `false`, re-apply, and notice what Terraform does to the existing bucket
