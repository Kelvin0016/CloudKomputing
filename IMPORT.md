# monitoring-tf — Import Guide

All resources target **us-east-1** (trail home region + billing metrics live there,
regardless of ap-southeast-5 being your usual working region).

## 1. Init first
```bash
terraform init
```

## 2. Import in this order (dependencies first)

```bash
# S3 bucket + its sub-resources
terraform import aws_s3_bucket.cloudtrail_logs aws-cloudtrail-logs-634680389229-c3613d76
terraform import aws_s3_bucket_versioning.cloudtrail_logs aws-cloudtrail-logs-634680389229-c3613d76
terraform import aws_s3_bucket_server_side_encryption_configuration.cloudtrail_logs aws-cloudtrail-logs-634680389229-c3613d76
terraform import aws_s3_bucket_policy.cloudtrail_logs aws-cloudtrail-logs-634680389229-c3613d76

# IAM role for CloudTrail -> CloudWatch Logs delivery
terraform import aws_iam_role.cloudtrail_cloudwatch CloudTrail-CloudWatch-Role
# NOTE: I don't have the exact inline/attached policy document for this role —
# only that it exists and does log delivery. After importing the role, run
# `terraform plan` and diff the aws_iam_role_policy against what's live:
#   aws iam list-role-policies --role-name CloudTrail-CloudWatch-Role
#   aws iam get-role-policy --role-name CloudTrail-CloudWatch-Role --policy-name <name>
# and adjust sns_and_alarms... (cloudtrail.tf) to match exactly before importing the policy.
terraform import aws_iam_role_policy.cloudtrail_cloudwatch CloudTrail-CloudWatch-Role:<actual-policy-name-from-above>

# CloudWatch Logs group
terraform import aws_cloudwatch_log_group.cloudtrail aws-cloudtrail-logs

# CloudTrail trail itself
terraform import aws_cloudtrail.main arn:aws:cloudtrail:us-east-1:634680389229:trail/my-cloudtrail

# Metric filters
terraform import aws_cloudwatch_log_metric_filter.iam_policy_changes aws-cloudtrail-logs:IAMPolicyChanges
terraform import aws_cloudwatch_log_metric_filter.root_account_login aws-cloudtrail-logs:RootAccountLogin
terraform import aws_cloudwatch_log_metric_filter.security_group_changes aws-cloudtrail-logs:SecurityGroupChanges

# SNS topic + subscription
terraform import aws_sns_topic.billing_alert arn:aws:sns:us-east-1:634680389229:billing-alert
terraform import aws_sns_topic_subscription.billing_alert_email arn:aws:sns:us-east-1:634680389229:billing-alert:397f7e16-08d1-42b9-b303-f886a204410c

# CloudWatch alarms
terraform import aws_cloudwatch_metric_alarm.billing billing-alert
terraform import aws_cloudwatch_metric_alarm.iam_policy_changes IAMPolicyChanges-Alarm
terraform import aws_cloudwatch_metric_alarm.root_account_login RootAccountLogin-Alarm
terraform import aws_cloudwatch_metric_alarm.security_group_changes SecurityGroupChanges-Alarm
```

## 3. Verify
```bash
terraform plan
```
Goal: **zero changes**. If plan shows a diff, it almost always means one of:
- The IAM role policy document doesn't match exactly (see note above — the most likely mismatch)
- `bucket_key_enabled` or another S3 sub-attribute drifted
- Tag differences (if any tags exist on the live resources that aren't in the `.tf` — run
  `aws resourcegroupstaggingapi get-resources --region us-east-1` to check)

Fix the `.tf` to match reality, not the other way around — the goal of this exercise is a
codebase that accurately describes what's running, not resources with new settings.

## 4. Known gaps / things flagged during discovery (not blockers, just noted)
- S3 bucket versioning is **disabled** on the log bucket — a real hardening opportunity later,
  but keep it "as-is" for the import so plan comes back clean, then propose the change as a
  separate, deliberate PR (nice writeup material: "found + fixed via IaC review").
- Same account, no other regions had duplicate monitoring — ap-southeast-5 came back empty for
  both alarms and SNS, so this module is deliberately us-east-1-only.
