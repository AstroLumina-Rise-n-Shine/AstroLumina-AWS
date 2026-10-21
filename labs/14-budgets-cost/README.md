# 14 — Budget alerts

Cloud costs are nobody's problem until they're everyone's problem. AWS Budgets
tracks spend (or usage) against a limit you set and fires notifications when
crossing thresholds — usually over SNS. This lab creates a $50/month budget
that alerts at 50%, 80% and 100% via an SNS topic subscribed by email.

## What you'll learn

- What AWS Budgets tracks and how COST budgets differ from USAGE-type ones
- That the limit is expressed as a decimal string (the API treats it as text)
- How budget notifications are delivered: thresholds trigger SNS messages
- Why SNS subscribers must confirm their email (real AWS) before they get alerts
- That alerts at multiple thresholds (50/80/100) catch burn before it hurts

## Resources created

- 1 COST/FIXED monthly budget `astrolumina-learning-budget-monthly` limited to 50
- 3 budget notifications (thresholds 50%, 80%, 100%)
- 1 SNS topic (named after the budget) for alert delivery
- 1 email subscription: `cost-alerts@example.com`

## Run it

```bash
cd labs/14-budgets-cost
terraform init
terraform apply
```

## Verify

```bash
# One-time setup: point the AWS CLI at Floci with dummy credentials
export AWS_ACCESS_KEY_ID=111111111111 AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1 AWS_ENDPOINT_URL=http://localhost:4566

# The budget exists with limit 50 and its notifications
aws --no-cli-pager budgets describe-budgets --account-id 111111111111

# The alert topic the budget publishes to
aws --no-cli-pager sns list-topics

# The email subscription (here: unconfirmed, as expected for the placeholder address)
aws --no-cli-pager sns list-subscriptions
```

Also open the Floci dashboard at http://localhost:8080 and check the budgets
and SNS views.

## Destroy

```bash
terraform destroy
```

## Try next

- Add a second budget, e.g. USAGE-based with `time_unit = "DAILY"`, tracking EC2 hours
- Change a threshold to [25, 50, 75, 90, 100] and diff the plan to see the notification set update
- Subscribe your real address and click the confirmation link in SNS on real AWS
