# 02 — NoSQL table (DynamoDB)

Here you stand up a DynamoDB table with a composite key — a string partition key
`pk` plus a numeric sort key `sk` — billed on-demand, and seed two items into it
straight from Terraform. It runs on Floci, so scanning and re-seeding is free
and instant.

## What you'll learn

- Choosing a **key schema**: what `hash_key` vs `range_key` mean and how the type (`S`/`N`) matters
- Why **PAY_PER_REQUEST** is the sensible default for small/learning tables
- Seeding rows with `aws_dynamodb_table_item` and `jsonencode`
- Inspecting a table with the DynamoDB CLI

## Resources created

- Table `astrolumina-learning-dynamodb` — partition key `pk` (string), sort key `sk` (number), on-demand billing, tags `Environment=learning`, `lab=02-dynamodb`
- Two items under partition `user#1`: `sk = 1` ("first row") and `sk = 2` ("second row")

## Run it

```bash
cd labs/02-dynamodb
terraform init
terraform apply
```

## Verify

One-time environment setup (dummy Floci credentials, region, and endpoint):

```bash
export AWS_ACCESS_KEY_ID=111111111111 AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1 AWS_ENDPOINT_URL=http://localhost:4566
```

Read every row back, then inspect the table definition:

```bash
aws --no-cli-pager dynamodb scan --table-name astrolumina-learning-dynamodb
aws --no-cli-pager dynamodb describe-table --table-name astrolumina-learning-dynamodb
```

In `describe-table` output, note that PITR (point-in-time recovery) shows
enabled — the module turns it on by default, which is what you'd want for
production tables as well. The Floci dashboard at http://localhost:8080 has a
DynamoDB view too.

## Destroy

```bash
terraform destroy
```

## Try next

- Add an item under a different partition (e.g. `user#2`) and re-scan to see partitions organize the data
- Pass `ttl_attribute = "expires_at"` to the module, add an `expires_at` epoch to your items, and watch DynamoDB delete them
- Switch `billing_mode` to `PROVISIONED` and set your own `read_capacity`/`write_capacity` to feel the difference
