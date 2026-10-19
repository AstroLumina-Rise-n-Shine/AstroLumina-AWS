# 13 — Site-to-site VPN

> **⚠️ PLAN-ONLY LAB ON FLOCI**: the Floci emulator does not implement the
> site-to-site VPN APIs yet (CreateCustomerGateway, CreateVpnGateway and
> CreateVpnConnection all return `UnsupportedOperation`). Use `terraform plan`
> here to study how the pieces fit together — `terraform apply` would hit real
> AWS and create real billable resources. **This lab is read/plan-only on
> Floci.**

A site-to-site VPN connects your on-premises network to a VPC over IPsec
tunnels. Two gateways describe the two ends — your router (customer gateway,
registered by public IP + BGP ASN) and AWS's side (VPN gateway attached to the
VPC) — and a VPN connection ties them together with two redundant tunnels.

## What you'll learn

- The three VPN objects: customer gateway, VPN gateway, VPN connection
- Why there are always **two** tunnels (redundancy across AWS endpoints)
- What a BGP ASN is and why the on-prem router needs one
- Static routes vs. BGP-learned routes for advertising on-prem CIDRs
- How routes get propagated into VPC route tables

## Resources created (in the plan)

- 1 VPC `10.48.0.0/16` with 1 public subnet (`10.48.1.0/24`)
- 1 customer gateway registered for public IP `203.0.113.10` with ASN 65000
  (TEST-NET-3 documentation IP, private ASN)
- 1 VPN gateway attached to the VPC
- 1 IPsec VPN connection (2 tunnels) with static routes to `192.168.0.0/16`

## Run it

```bash
cd labs/13-vpn
terraform init
terraform plan   # study the plan: 4 resources, all ec2-type APIs
```

`terraform plan` works fully offline against Floci (planning needs no API
calls for as-yet-uncreated resources). If you point this directory at real AWS
(`AWS_PROFILE=... terraform apply`) the same code deploys a real VPN.

## Verify

On Floci there is nothing to verify with the AWS CLI — the lab is plan-only
and creates nothing (by design). The value is in the **plan output**: read the
four planned resources and the attributes Terraform will send to the VPN APIs.

If you apply against real AWS instead, you would check with:

```bash
export AWS_ACCESS_KEY_ID=111111111111 AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1 AWS_ENDPOINT_URL=http://localhost:4566

aws --no-cli-pager ec2 describe-vpcs
aws --no-cli-pager ec2 describe-vpn-connections
```

...and the Floci dashboard at http://localhost:8080 will show nothing for this
lab — nothing was created, since only `terraform plan` was run.

## Destroy

Nothing to destroy on Floci (nothing was applied). If you applied this lab
against real AWS, run `terraform destroy` there before removing anything.

## Try next

- Change `static_routes_only` to `false` (the module supports it) and reason about what changes: BGP sessions learning routes instead of static entries
- Add route propagation: pass `route_table_ids = [<vpc route table>]` to the VPN module
- Study the generated AWS-side configuration (real AWS gives you a downloadable config for your router make/model)
