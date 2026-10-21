# 11 — HTTP entry point with an ALB

An Application Load Balancer (ALB) is the standard front door for HTTP traffic
in AWS: it accepts requests on one public DNS name, checks the health of
registered targets, and forwards traffic to the healthy ones. Here you build
the front door itself — VPC, subnets, security group, ALB, listener and an
(empty) target group — and learn how the pieces connect.

## What you'll learn

- The ALB anatomy: load balancer → listener → target group → targets
- Why an ALB requires at least two subnets in different AZs
- That security groups control both who reaches the listener and who the targets see
- The difference between `internal` and internet-facing ALBs (and why secure defaults exist)
- How target groups health-check targets instead of trusting them blindly

## Resources created

- 1 VPC (`10.47.0.0/16`) with 2 public subnets (`10.47.1.0/24`, `10.47.2.0/24`), an
  internet gateway and route tables
- 1 security group `astrolumina-learning-alb-sg` (HTTP from anywhere, all egress)
- 1 internet-facing ALB `astrolumina-learning-alb`
- 1 HTTP listener on port 80
- 1 IP target group (port 80, health check on `/`) — note: **empty**, there is no
  backend yet

## Run it

```bash
cd labs/11-alb-ingress
terraform init
terraform apply
```

## Verify

```bash
# One-time setup: point the AWS CLI at Floci with dummy credentials
export AWS_ACCESS_KEY_ID=111111111111 AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1 AWS_ENDPOINT_URL=http://localhost:4566

# The ALB exists and is internet-facing (Remember, the load balancer scheme)
aws --no-cli-pager elbv2 describe-load-balancers

# The listener forwards HTTP :80 to the target group
aws --no-cli-pager elbv2 describe-listeners

# The target group, its port (80) and its health check settings
aws --no-cli-pager elbv2 describe-target-groups

# Bonus: curl the ALB and see a 502 -- expected while the target group is empty
curl "http://$(terraform output -raw alb_dns_name)"
```

Also open the Floci dashboard at http://localhost:8080 and look at the ELB
section.

## Destroy

```bash
terraform destroy
```

## Try next

- There is no backend yet — register targets into the target group. Combine
  this with lab 05 (EC2 instances, `target_type = "instance"`) or lab 08
  (ECS Fargate tasks, `target_type = "ip"`).
- Add a second listener rule and target group (e.g. route `/api/*` elsewhere)
- In real AWS, swap the HTTP listener for HTTPS with an ACM certificate
