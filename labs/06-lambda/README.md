# 06 — Serverless function (Lambda)

A minimal Lambda lab: package a one-file Python handler with the archive
provider, wire up an execution role, and deploy it as `astrolumina-learning-hello`
against the Floci emulator. Floci runs Lambda functions for real, so after
`apply` you can invoke the function and watch your Python code execute.

## What you'll learn

- How a Lambda deployment package is built with `data "archive_file"`.
- Why every function needs an IAM execution role and what it may do.
- How handler, runtime and `source_code_hash` work together on redeploy.
- Passing configuration to code via environment variables.

## Resources created

- An IAM role `astrolumina-learning-lambda-role` trusting `lambda.amazonaws.com`,
  with the `AWSLambdaBasicExecutionRole` managed policy attached.
- A Lambda function `astrolumina-learning-hello` (Python 3.12, 128 MB, 3 s
  timeout) built from `src/handler.py` and configured with `GREETING`.

## Run it

```bash
cd labs/06-lambda
terraform init
terraform apply
```

## Verify

One-time export (Floci dummy credentials):

```bash
export AWS_ACCESS_KEY_ID=111111111111 AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1 AWS_ENDPOINT_URL=http://localhost:4566
```

Invoke the function — Floci actually runs your Python:

```bash
aws --no-cli-pager lambda invoke --function-name astrolumina-learning-hello --payload '{}' /tmp/lambda-out.json --cli-binary-format raw-in-base64-out
cat /tmp/lambda-out.json
```

Inspect the function configuration:

```bash
aws --no-cli-pager lambda get-function --function-name astrolumina-learning-hello
```

Also look at the Lambda page on the Floci dashboard: <http://localhost:8080>.

## Destroy

```bash
terraform destroy
```

## Try next

- Edit `src/handler.py` (or `GREETING`) and re-apply: the `source_code_hash`
  changes, so Terraform re-uploads the code — the Lambda redeploy flow.
- Raise `memory_size` / `timeout` on the module and see the config update.
- Point a new managed policy at `module.hello_lambda.function_arn` to give the
  function S3 read access (pair with labs/01-s3).
