# AstroLumina-AWS — Learning Labs

Hands-on Terraform labs that teach AWS by deploying real (well, emulated)
infrastructure against **[Floci](https://floci.io)**, a local AWS emulator.
Every lab is a small, self-contained Terraform configuration that composes
reusable modules from the
[AstroLumina-Terraform-Library](https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library),
applies them through the Terraform AWS provider pointed at Floci, and then
verifies the result with plain AWS CLI commands — the same commands you
would run against a real account. Running costs: zero. Risk to real AWS:
zero.

## How it fits together

- **AstroLumina-Terraform-Library** — the building blocks: one reusable
  Terraform module per AWS concept (`aws_s3_bucket`, `aws_network`,
  `aws_eks`, ...). The labs call these over `git::` sources pinned to the
  Library release tag `1.0.4`. Library changes are developed, merged and
  released there first; this repo consumes the tagged release.
- **AstroLumina-Terraform** — the actual AstroLumina infrastructure repo
  (the production target). It reuses the same Library modules in earnest.
  These labs exist so that before a module reaches production there, it has
  been applied, inspected and destroyed dozens of times locally, here.
- **This repo (AstroLumina-AWS)** — the learning track: labs + guides, no
  real credentials ever required.

## Prerequisites

- **Terraform >= 1.6** — install guide: [docs/01-terraform-install.md](docs/01-terraform-install.md)
- **AWS CLI v2** — install guide: [docs/02-floci-aws-cli.md](docs/02-floci-aws-cli.md)
- **Docker** (Floci runs the emulated services and the heavier lab
  resources — RDS, Lambda, ECS, EKS, EC2 — as real local containers)
- **Floci running** (`floci start`) — full wiring:
  [docs/03-terraform-floci.md](docs/03-terraform-floci.md)

## Quickstart (lab 01 — S3)

```bash
floci start

cd labs/01-s3
terraform init
terraform apply -auto-approve
```

Verify with the shared CLI environment:

```bash
export AWS_ACCESS_KEY_ID=111111111111 \
       AWS_SECRET_ACCESS_KEY=test \
       AWS_DEFAULT_REGION=us-east-1 \
       AWS_ENDPOINT_URL=http://localhost:4566

aws s3 ls
aws s3 cp s3://astrolumina-learning-s3-data/hello.txt -

aws sts get-caller-identity
# Account: 111111111111
```

Browse the results in the Floci dashboard at
**http://localhost:8080** — fill that export line into every new shell
(or follow [docs/02-floci-aws-cli.md](docs/02-floci-aws-cli.md)) before
running any `aws` command from these labs.

## Lab index

| Lab | Topic | What it teaches |
| --- | --- | --- |
| [labs/01-s3](labs/01-s3) | Object storage | Bucket module, versioning + SSE, direct object resource, reading it back with the CLI |
| [labs/02-dynamodb](labs/02-dynamodb) | NoSQL table | Table module with hash/range keys, PAY_PER_REQUEST billing, seeding items via `jsonencode` |
| [labs/03-iam](labs/03-iam) | Identity | Roles vs users, managed and inline policies, access keys (and why the output is sensitive) |
| [labs/04-vpc-network](labs/04-vpc-network) | Networking | VPC + subnets + IGW from a single module, hand-written security groups |
| [labs/05-ec2](labs/05-ec2) | Compute | Instance module, AMIs, user data, public IPs — runs as a real Floci container |
| [labs/06-lambda](labs/06-lambda) | Serverless | `archive_file` data source, function module, invoking through the CLI |
| [labs/07-rds](labs/07-rds) | Databases | RDS in private subnets, DB security group, why deletion protection gets a lab override |
| [labs/08-ecs-fargate](labs/08-ecs-fargate) | Containers | Fargate service module, task CPU/memory sizing, a real nginx container locally |
| [labs/09-eks](labs/09-eks) | Kubernetes | The heaviest lab: EKS cluster + managed node group + KMS encryption, real k3s control plane |
| [labs/10-route53-dns](labs/10-route53-dns) | DNS | Hosted zones and typed record sets from a map of objects |
| [labs/11-alb-ingress](labs/11-alb-ingress) | Load balancing | ALB + listener + target group, internet-facing vs the module's internal default |
| [labs/12-security](labs/12-security) | Security baseline | KMS key, GuardDuty, Security Hub, CloudTrail with CMK encryption — one module |
| [labs/13-vpn](labs/13-vpn) | Site-to-site VPN | **Plan-only on Floci** (the VPN APIs return UnsupportedOperation) — study the plan, apply on real AWS |
| [labs/14-budgets-cost](labs/14-budgets-cost) | Cost | Budget module with thresholds, SNS notifications, `aws budgets describe-budgets` |
| [labs/15-cross-account](labs/15-cross-account) | Cross-account access | Two-account model, trust policy + external id, assuming a role in account A from account B |

Guides beyond the labs: [docs/](docs/) — Terraform install, Floci + AWS CLI
setup, Terraform↔Floci wiring, EKS mental model, Floci web consoles.

## The two-account model

Labs deploy against a fixed, two-account back story (Floci identifies an
account by the access key: a 12-digit key *is* the account ID):

- **Account A** — `111111111111`, access key `111111111111` — where most
  labs deploy. There is nothing real here; the credentials are documented
  emulator dummies, never reuse them anywhere else.
- **Account B** — `222222222222`, access key `222222222222` — exists only
  for [labs/15-cross-account](labs/15-cross-account), which demonstrates
  IAM role assumption from a second account.

## Validate locally (without waiting for a Library release)

CI validates the labs against the pinned Library release tag (`1.0.4`), so
a Library change must be merged and released, and the ref bumped here,
before this repo's `validate` job sees it. To test your lab **now**, against
your local Library checkout:

```bash
./scripts/check-local.sh
# Optionally point at a different Library checkout:
LIB_PATH=~/Workdir/AstroLumina/AstroLumina-Terraform-Library ./scripts/check-local.sh
```

The script copies each lab into `.local-check/`, rewrites module sources to
the local Library path, then runs `terraform init -backend=false` and
`terraform validate` per lab, printing PASS/FAIL. Working tree, untouched.

See [docs/04-eks-clusters.md](docs/04-eks-clusters.md) for the EKS mental
model and [docs/05-floci-consoles.md](docs/05-floci-consoles.md) for the
dashboard setup (port 8080).

## CI

CI (`.github/workflows/validate.yml`) runs two checks only: `terraform fmt
-check -recursive` and `terraform validate` per lab. **No `apply` ever runs
in CI** — nothing is deployed from a pipeline, and the validate job resolves
module sources from the pinned Library release tag (`1.0.4`), so a Library
change must be released and the ref bumped here before CI sees it.

## Rules of the repo

- **All changes via PR.** Direct pushes to `main` are not the workflow.
- **Docs in English.** Code comments too.
- Fixed resource names (`astrolumina-learning-<thing>`, no random
  suffixes), `environment = "learning"` and a `lab` tag on every module
  call — see any lab for the pattern.
- Everything is disposable: every lab ends with `terraform destroy` and
  Floci keeps no trace that matters.
