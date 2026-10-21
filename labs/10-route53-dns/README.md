# 10 — DNS with Route 53

Route 53 is AWS's managed DNS service: it stores hosted zones (domains) and the
record sets under them. In this lab you create one public hosted zone,
`astrolumina-learning.test`, plus an A record, a CNAME record and a second A
record, all managed declaratively from Terraform.

## What you'll learn

- What a hosted zone is and how Route 53 stores DNS data
- How record sets are declared: name, type (A/CNAME), TTL and values
- Why "@" means "the zone apex" (the domain itself)
- How Terraform maps of objects can model a whole record table
- That DNS names/records have no meaning until a registrar (or emulator) is involved

## Resources created

- One public Route 53 hosted zone: `astrolumina-learning.test`
- Record sets:
  - `@` → A 300 `192.0.2.10`
  - `www` → CNAME 300 `astrolumina-learning.test`
  - `api` → A 300 `192.0.2.11`
  - (the zone's NS/SOA records are created automatically)

## Run it

```bash
cd labs/10-route53-dns
terraform init
terraform apply
```

## Verify

```bash
# One-time setup: point the AWS CLI at Floci with dummy credentials
export AWS_ACCESS_KEY_ID=111111111111 AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1 AWS_ENDPOINT_URL=http://localhost:4566

# List the hosted zones -- you should see astrolumina-learning.test
aws --no-cli-pager route53 list-hosted-zones

# Inspect the record sets (use the zone id printed by terraform output zone_id)
aws --no-cli-pager route53 list-resource-record-sets --hosted-zone-id <zone_id>

# Or all in one line
aws --no-cli-pager route53 list-resource-record-sets \
  --hosted-zone-id "$(terraform output -raw zone_id)"
```

Also open the Floci dashboard at http://localhost:8080 and look at the Route 53
hosted zone.

## Destroy

```bash
terraform destroy
```

## Try next

- Add a `mail` MX record or a TXT record (map shape accepts any type)
- Flip the zone to `private_zone = true` with a VPC id (needs a VPC, see lab 04)
- Point the A records at a real ALB from lab 11 using the ALB's DNS name
