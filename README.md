# monitoring-tf

Terraform module that codifies the AWS account's security monitoring stack —
originally set up manually via the console, now fully imported and managed
as code.

## What this manages

- **CloudTrail** — multi-region trail (`my-cloudtrail`), management events only,
  log file validation enabled
- **S3** — the CloudTrail log bucket (SSE-S3 encryption, bucket policy scoped
  to CloudTrail's write/ACL-check permissions)
- **CloudWatch Logs** — log group CloudTrail streams into, plus an IAM role +
  managed policy granting CloudTrail permission to write to it
- **CloudWatch Logs Metric Filters** — three filters watching CloudTrail events:
  - IAM policy changes (create/delete/attach/detach policies)
  - Root account login
  - Security group changes (ingress/egress authorize/revoke, SG create/delete)
- **CloudWatch Alarms** — four alarms:
  - Billing (`AWS/Billing` EstimatedCharges over a configurable USD threshold)
  - One per metric filter above (fires on any matching event)
- **SNS** — a topic (`billing-alert`) all four alarms notify, with an email
  subscription for notifications

## Why us-east-1

This entire module targets `us-east-1` deliberately, regardless of which
region day-to-day infra (e.g. the Flask app / CI-CD stack) runs in:
- `AWS/Billing` metrics are only published in us-east-1, account-wide
- This trail's home region is us-east-1

## Structure

| File | Contents |
|---|---|
| `providers.tf` | Terraform + AWS provider config |
| `variables.tf` | Input variables (region, trail name, bucket name, alert email, billing threshold) |
| `locals.tf` | Account ID lookup (`aws_caller_identity`) + derived trail ARN |
| `s3.tf` | Log bucket, versioning, encryption, bucket policy |
| `cloudtrail.tf` | Trail, CloudWatch Logs group, IAM role + managed policy for log delivery |
| `metric_filters.tf` | The three CloudWatch Logs metric filters |
| `sns_and_alarms.tf` | SNS topic/subscription + all four alarms |
| `IMPORT.md` | Step-by-step `terraform import` commands used to adopt the pre-existing resources into state |

## Usage

```bash
terraform init
```

Create a `terraform.tfvars` (gitignored — never commit real values):

```hcl
cloudtrail_bucket_name = "<your-cloudtrail-log-bucket-name>"
billing_alert_email    = "<your-email>"
```

```bash
terraform plan
terraform apply
```

Since the account ID is resolved dynamically via `data.aws_caller_identity`,
this module is portable to a fresh AWS account as-is — just supply a new,
globally-unique `cloudtrail_bucket_name` and your own alert email.

## Known accepted state

- S3 bucket versioning is intentionally left **disabled** to match the
  existing resource on import. Flagged as a future hardening candidate
  (would protect CloudTrail logs from accidental/malicious deletion) —
  not yet implemented so `terraform plan` stays a clean diff against reality.

## History

Originally built by hand via the AWS console as part of Phase 3 of a
self-directed cloud security study plan. This module retroactively
codifies that setup into Terraform so the monitoring stack is reproducible,
version-controlled, and drift-detectable going forward.
