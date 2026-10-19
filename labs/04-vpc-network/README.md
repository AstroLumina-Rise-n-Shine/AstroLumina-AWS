# 04 — VPC from scratch

This lab builds the networking backbone every other lab stands on: a VPC with
an internet gateway, layered into two public and two private subnets across two
availability zones, plus a security group acting as the web-tier firewall. All
of it exists inside the Floci emulator, so you can tear it down guilt-free.

## What you'll learn

- What a **VPC CIDR block** is and how it carves the private IP space (`10.42.0.0/16`)
- Splitting a VPC into **public vs private subnets** and pinning them to AZs positionally
- Why `enable_nat_gateway = false` is the module's cost-conscious default
- Writing a **security group** with ingress/egress rules (stateful firewall — no return rules needed)

## Resources created

- VPC `astrolumina-learning-network` (`10.42.0.0/16`) with an internet gateway, tags `Environment=learning`, `lab=04-vpc-network`
- Public subnets `10.42.1.0/24` (us-east-1a) and `10.42.2.0/24` (us-east-1b) with public routes
- Private subnets `10.42.11.0/24` (us-east-1a) and `10.42.12.0/24` (us-east-1b) — no NAT gateway (off by default; Floci NAT support unverified)
- Security group `astrolumina-learning-web-sg` in the VPC — inbound 80 + 443 from `0.0.0.0/0`, all egress

## Run it

```bash
cd labs/04-vpc-network
terraform init
terraform apply
```

## Verify

One-time environment setup (dummy Floci credentials, region, and endpoint):

```bash
export AWS_ACCESS_KEY_ID=111111111111 AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1 AWS_ENDPOINT_URL=http://localhost:4566
```

Find the VPC (look for the tag `lab=04-vpc-network`), then the subnets, then
the security group — plug the SG id from `terraform output security_group_id`
into the last command:

```bash
aws --no-cli-pager ec2 describe-vpcs
aws --no-cli-pager ec2 describe-subnets
aws --no-cli-pager ec2 describe-security-groups --group-ids <sg_id>
```

The Floci dashboard at http://localhost:8080 visualizes the **EC2** network
objects (VPCs, subnets, security groups) as well.

## Destroy

```bash
terraform destroy
```

## Try next

- Set `enable_nat_gateway = true` and re-apply to see what a NAT adds to the plan (Floci NAT support unverified)
- Add a `labs/05-ec2`-style instance in the public subnets to test the security group in anger
- Shrink the VPC CIDR to `/17` and watch Terraform resize the plan (spoiler: changing a CIDR replaces the VPC)
