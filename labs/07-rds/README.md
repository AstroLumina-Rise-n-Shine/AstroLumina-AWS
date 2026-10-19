# 07 — Managed database (RDS Postgres)

A private managed Postgres: two private subnets form the DB subnet group, a
security group admits port 5432 only from the lab VPC, and Floci boots the
instance as a real Postgres container. This is the shape of every
production "database in its own network" setup, at learning-lab scale.

## What you'll learn

- Why RDS instances live in at least two subnets of *different* AZs.
- Locking a database down with a security group scoped to the VPC CIDR.
- What `deletion_protection` and `skip_final_snapshot` control at destroy time.
- Connection details come back as outputs: address, port, database name.

## Resources created

- VPC `astrolumina-learning-rds-net` (10.44.0.0/16) with private subnets
  10.44.11.0/24 and 10.44.12.0/24 in us-east-1a/b (no public subnets).
- Security group `astrolumina-learning-db-sg`: inbound 5432 from 10.44.0.0/16 only.
- RDS instance `astrolumina-learning-db` (postgres, db.t3.micro, database
  `astrolumina`, user `astrolumina`, password `floci-learning-password` —
  a dummy for the emulator, never a real secret).

## Run it

```bash
cd labs/07-rds
terraform init
terraform apply
```

## Verify

One-time export (Floci dummy credentials):

```bash
export AWS_ACCESS_KEY_ID=111111111111 AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1 AWS_ENDPOINT_URL=http://localhost:4566
```

Describe the instance — status may take a bit, Floci boots a real Postgres:

```bash
aws --no-cli-pager rds describe-db-instances --db-instance-identifier astrolumina-learning-db
```

Also look at the RDS page on the Floci dashboard: <http://localhost:8080>.

## Destroy

```bash
terraform destroy
```

## Try next

- Flip `publicly_accessible = true` and see why the SG still blocks outside
  traffic — two layers, each with its own job.
- Change `engine` to `mysql` (and the SG port to 3306) for a second engine.
- Connect from inside the network: run a psql container in the same VPC
  (pair with labs/08-ecs-fargate, private subnets this time).
