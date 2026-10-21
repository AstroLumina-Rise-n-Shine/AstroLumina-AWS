# 05 — Compute instance (EC2)

This lab launches your first "server": a tiny EC2 instance running Ubuntu,
placed in a fresh public subnet and gated by a security group. On Floci the
instance is not a metaphor — Floci boots it as a real local container, so a
`running` state here means the box actually exists on your machine.

## What you'll learn

- Building a **network + compute stack** in one configuration and wiring outputs into inputs
- What a **public subnet** with `map_public_ip_on_launch` really implies (internet-facing exposure)
- Passing a **user_data** boot script that runs on first boot
- Reading instance state with `describe-instances`

## Resources created

- VPC `astrolumina-learning-ec2-net` (`10.43.0.0/16`) with IGW and a public subnet `10.43.1.0/24` (us-east-1a); public IPs auto-assigned (opt-in comment in code); tags `Environment=learning`
- Security group `astrolumina-learning-ec2-sg` — inbound 22 + 80 from `0.0.0.0/0`, all egress
- Instance `astrolumina-learning-web-01` — `ami-ubuntu2404-amd64`, `t3.micro`, user_data writes `Hello from Floci` to `/etc/motd`

## Run it

```bash
cd labs/05-ec2
terraform init
terraform apply
```

Note: Floci runs the instance as a real Docker container, so the first apply
may take a little while while the image boots.

## Verify

One-time environment setup (dummy Floci credentials, region, and endpoint):

```bash
export AWS_ACCESS_KEY_ID=111111111111 AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1 AWS_ENDPOINT_URL=http://localhost:4566
```

Find the instance by name and check its state is `running`:

```bash
aws --no-cli-pager ec2 describe-instances --filters Name=tag:Name,Values=astrolumina-learning-web-01
```

Also try `curl http://<public_ip>/` or `ssh` from your terminal if a local
runtime image exposes those ports — the box is a real container on your host.
The Floci dashboard at http://localhost:8080 lists running instances under
**EC2**.

## Destroy

```bash
terraform destroy
```

## Try next

- Swap the AMI for `ami-debian12` or `ami-amazonlinux2023-arm64` and watch what changes (instance type must match the CPU architecture — for ARM pick an `a1`/`m6g` class)
- Change user_data to install nginx and serve something on port 80, then curl it
- Move the instance into the private subnet (add one via the network module) and observe how it loses its public IP
