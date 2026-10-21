# 08 — Containers without servers (ECS Fargate)

Fargate means "a container, no EC2 to manage": define CPU/memory, an image and
a network, and ECS keeps one task running. Floci executes the task as a real
local container, so `nginx:alpine` genuinely listens on port 80 after apply.

## What you'll learn

- The ECS hierarchy: cluster → service → task definition → containers.
- Fargate sizing: `cpu` 256 units pairs with `memory` 512 MiB.
- Why a task needs `assign_public_ip` in public subnets (image pulls, replies).
- Service desired_count: ECS reconciles reality toward the number you declare.

## Resources created

- VPC `astrolumina-learning-ecs-net` (10.45.0.0/16) with public subnets
  10.45.1.0/24 and 10.45.2.0/24, auto public IPs on.
- Security group `astrolumina-learning-ecs-sg`: inbound 80 from anywhere,
  all egress.
- ECS cluster/service `astrolumina-learning-ecs` running 1 × nginx:alpine
  (256/512) on container port 80.

## Run it

```bash
cd labs/08-ecs-fargate
terraform init
terraform apply
```

## Verify

One-time export (Floci dummy credentials):

```bash
export AWS_ACCESS_KEY_ID=111111111111 AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1 AWS_ENDPOINT_URL=http://localhost:4566
```

Inspect the cluster and service (the service name equals the cluster name here):

```bash
aws --no-cli-pager ecs list-clusters
aws --no-cli-pager ecs list-services --cluster astrolumina-learning-ecs
aws --no-cli-pager ecs describe-services --cluster astrolumina-learning-ecs --services astrolumina-learning-ecs
```

Also look at the ECS page on the Floci dashboard: <http://localhost:8080>
(the task runs as a real local container).

## Destroy

```bash
terraform destroy
```

## Try next

- Set `desired_count = 2` and re-apply: watch the service scale out.
- Swap `image` for something with state (e.g. `hashicorp/http-echo`) and a
  different `container_port` / SG port.
- Put an ALB in front (pair with labs/11-alb-ingress) so URLs, not port
  mappings, are the entry point.
