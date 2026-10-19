# 12 — Account security baseline

A production AWS account ships with hygiene: encryption keys you control,
threat detection, a security postures service and an audit trail of every API
call. This lab deploys all four in one shot — a customer-managed KMS key, a
GuardDuty detector, Security Hub and a CloudTrail trail (CMK-encrypted, with
log file validation) feeding its own trail bucket.

## What you'll learn

- Why you want customer-managed KMS keys instead of AWS-owned encryption
- What GuardDuty detectors collect (threat findings from logs/traffic)
- What Security Hub aggregates (compliance and security findings)
- How CloudTrail trails record API history into S3 with log file validation
- That the trail bucket must be sealed down with a bucket policy — the module does it for you

## Resources created

- 1 customer-managed KMS key with alias `alias/astrolumina-learning-security`
- 1 GuardDuty detector
- Security Hub **switched off on Floci** (`enable_security_hub = false`): the
  emulator cannot disable Security Hub once enabled, so the provider resource
  cannot round-trip; on real AWS flip the toggle to manage it too
- 1 S3 bucket `astrolumina-learning-security-cloudtrail` with a lock-down bucket policy
- 1 CloudTrail trail `astrolumina-learning-security` — CMK-encrypted, log file
  validation enabled, writing to the trail bucket

## Run it

```bash
cd labs/12-security
terraform init
terraform apply
```

## Verify

```bash
# One-time setup: point the AWS CLI at Floci with dummy credentials
export AWS_ACCESS_KEY_ID=111111111111 AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1 AWS_ENDPOINT_URL=http://localhost:4566

# The customer-managed key, then its alias
aws --no-cli-pager kms list-keys
aws --no-cli-pager kms list-aliases

# The threat-detection detector
aws --no-cli-pager guardduty list-detectors

# Security Hub is not managed by this lab on Floci (see "Resources created");
# this reads the emulator's own hub state. On real AWS the module manages it.
aws --no-cli-pager securityhub describe-hub

# The audit trail and its current status (IsLogging should be true)
aws --no-cli-pager cloudtrail describe-trails
aws --no-cli-pager cloudtrail get-trail-status --name astrolumina-learning-security

# The sealed trail bucket
aws s3 ls
```

Also open the Floci dashboard at http://localhost:8080 and browse the KMS,
GuardDuty, Security Hub and CloudTrail views.

## Destroy

```bash
terraform destroy
```

## Try next

- Look at the trail bucket's policy (`aws s3api get-bucket-policy --bucket astrolumina-learning-security-cloudtrail`) and find what CloudTrail is allowed to do
- Flip a toggle and re-apply to watch declarative toggles cascade (e.g.
  `enable_guardduty = false`; `enable_security_hub = true` needs real AWS)
- Attach the KMS key from this lab to encryption elsewhere (this exact pattern is used inside lab 09's EKS setup)
