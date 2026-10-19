# 15 — Cross-account access (assume-role, the interview classic)

One of the most common AWS architecture questions: *how does an application in
account B read data owned by account A?* Answer: account A defines an IAM role
whose trust policy allows account B, account B's permission policy allows
assuming that role, and a session is created via `sts:AssumeRole` — with an
external ID guarding against the confused-deputy problem. This lab builds the
whole chain in Floci: a bucket + role in account A, a user in account B — plus
a follow-up config (`verify-assumed/`) that actually assumes the role through
Terraform to prove it works.

## What you'll learn

- The direction of trust: account A's role trusts account B (not the other way round)
- Why an external ID protects you when two parties control the accounts
- The two-policy handshake: A's trust policy + B's permission policy must both allow the call
- Least privilege inside the assumed session (the inline policy grants only the bucket)
- That `sts:AssumeRole` returns **temporary credentials** (AccessKeyId + SecretAccessKey + SessionToken) instead of long-lived keys

## Resources created

Account A (`111111111111`):
- 1 S3 bucket `astrolumina-learning-cross-data` (versioning enabled)
- 1 IAM role `astrolumina-learning-cross-role` trusting account `222222222222`
  with external ID `astrolumina-learning`, inline policy `bucket-rw`
  (ListBucket on the bucket; GetObject/PutObject on the bucket objects only)

Account B (`222222222222`):
- 1 IAM user `astrolumina-learning-account-b-app` with access key, inline
  policy `assume-role` allowing `sts:AssumeRole` on the role ARN

Proof:
- `verify-assumed/` — a second Terraform config whose provider starts from
  B's keys and assumes A's role; its `assumed_account_id` output must print
  `111111111111` (account A), proving the whole chain.

## Run it

```bash
cd labs/15-cross-account
terraform init
terraform apply
```

Then the proof — the role must exist first, which is exactly why it is a
separate config (a provider cannot assume a role the same apply is about to
create):

```bash
cd verify-assumed
terraform init
terraform apply
```

`terraform output assumed_account_id` should print `111111111111` — Terraform
just proved the cross-account assume works, using account B's static keys.
Destroy it with `terraform destroy` (data-only config, nothing to clean up),
then destroy the main config from the parent directory.

## Verify

```bash
# One-time setup: point the AWS CLI at Floci with dummy credentials
export AWS_ACCESS_KEY_ID=111111111111 AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1 AWS_ENDPOINT_URL=http://localhost:4566

# Account A: the role exists with the expected trust policy
aws --no-cli-pager iam get-role --role-name astrolumina-learning-cross-role
aws --no-cli-pager iam get-role-policy --role-name astrolumina-learning-cross-role --policy-name bucket-rw

# The CLI demo, from account B's point of view:
export AWS_ACCESS_KEY_ID=222222222222 AWS_SECRET_ACCESS_KEY=test

# Assume A's role using B's static keys -- returns temporary credentials
CREDS=$(aws --no-cli-pager sts assume-role \
  --role-arn arn:aws:iam::111111111111:role/astrolumina-learning-cross-role \
  --role-session-name demo \
  --external-id astrolumina-learning)

export AWS_ACCESS_KEY_ID=$(echo "$CREDS" | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo "$CREDS" | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo "$CREDS" | jq -r '.Credentials.SessionToken')

# Who am I (through the assumed session)? Should show the assumed role ARN in account A
aws --no-cli-pager sts get-caller-identity

# Read/write the bucket from the assumed session
aws s3 cp s3://astrolumina-learning-cross-data/notes.txt - || echo "(file not yet uploaded; upload one from account A first)"
```

> **Floci limitation**: trust policies are **not enforced** by the emulator —
> any account can assume any role. The JSON here is the shape real AWS would
> enforce (the trust policy, the external ID condition, the least-privilege
> inline policy); Floci simply accepts the calls, so treat the CLI result as a
> walkthrough of the real flow.

Also open the Floci dashboard at http://localhost:8080 and browse the IAM users
in both accounts and the S3 bucket.

## Destroy

```bash
terraform destroy
```

## Try next

- Change the external ID to something else in the role only (not the provider) and watch the assume-side check fail on real AWS — the lesson: external ID must match on both sides
- Add `max_session_duration` tuning (the module supports it) and reason about session length trade-offs
- Swap the user in account B for an OIDC/SAML identity to see federation-style cross-account access patterns
