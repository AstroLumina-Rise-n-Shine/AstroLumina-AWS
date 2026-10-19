# 09 — Kubernetes control plane (EKS)

The heaviest lab in the series: EKS provisions a managed Kubernetes control
plane plus a one-node managed node group, and Floci runs it as a real k3s
control plane. The first apply can take several minutes — grab a coffee while
the cluster comes up.

## What you'll learn

- What a "managed control plane" means: EKS runs masters, you run workers.
- Envelope-encrypting Kubernetes Secrets with a customer-managed KMS key.
- Managed node groups: `instance_types` plus desired/min/max sizes.
- Checking cluster health with the EKS API (kubectl optional).

## Resources created

- VPC `astrolumina-learning-eks-net` (10.46.0.0/16) with public subnets
  10.46.1.0/24 and 10.46.2.0/24, auto public IPs on.
- Customer-managed KMS key `alias/astrolumina-learning-eks-kms` (from the
  security baseline module, with GuardDuty/Security Hub/CloudTrail disabled —
  this lab only needs the key; those services are covered by labs/12-security).
- EKS cluster `astrolumina-learning` (Kubernetes 1.29) with a managed node
  group (t3.small, 1 desired / 1 min / 1 max), secrets encrypted with the CMK.

## Run it

```bash
cd labs/09-eks
terraform init
terraform apply
```

## Verify

One-time export (Floci dummy credentials):

```bash
export AWS_ACCESS_KEY_ID=111111111111 AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1 AWS_ENDPOINT_URL=http://localhost:4566
```

Describe the cluster — wait for status `ACTIVE`, first apply takes several
minutes because Floci boots a real control plane:

```bash
aws --no-cli-pager eks describe-cluster --name astrolumina-learning
aws --no-cli-pager eks list-nodegroups --cluster-name astrolumina-learning
```

Also look at the EKS page on the Floci dashboard: <http://localhost:8080>.

## Destroy

```bash
terraform destroy
```

## Try next

- bump the node group to `desired_size = 2` and re-apply to watch it scale.
- Once the cluster is ACTIVE, generate a kubeconfig with
  `aws eks update-kubeconfig` and inspect nodes with kubectl.
- Add a second cluster in a different VPC (labs/08 shows the network pattern)
  and compare apply times.
