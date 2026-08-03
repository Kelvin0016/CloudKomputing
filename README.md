##### \# monitoring-tf

##### 

##### Terraform module that codifies the AWS account's security monitoring stack —

##### originally set up manually via the console, now fully imported and managed

##### as code.

##### 

##### \## What this manages

##### 

##### \- \*\*CloudTrail\*\* — multi-region trail (`my-cloudtrail`), management events only,

##### &#x20; log file validation enabled

##### \- \*\*S3\*\* — the CloudTrail log bucket (SSE-S3 encryption, bucket policy scoped

##### &#x20; to CloudTrail's write/ACL-check permissions)

##### \- \*\*CloudWatch Logs\*\* — log group CloudTrail streams into, plus an IAM role +

##### &#x20; managed policy granting CloudTrail permission to write to it

##### \- \*\*CloudWatch Logs Metric Filters\*\* — three filters watching CloudTrail events:

##### &#x20; - IAM policy changes (create/delete/attach/detach policies)

##### &#x20; - Root account login

##### &#x20; - Security group changes (ingress/egress authorize/revoke, SG create/delete)

##### \- \*\*CloudWatch Alarms\*\* — four alarms:

##### &#x20; - Billing (`AWS/Billing` EstimatedCharges over a configurable USD threshold)

##### &#x20; - One per metric filter above (fires on any matching event)

##### \- \*\*SNS\*\* — a topic (`billing-alert`) all four alarms notify, with an email

##### &#x20; subscription for notifications

##### 

##### \## Why us-east-1

##### 

##### This entire module targets `us-east-1` deliberately, regardless of which

##### region day-to-day infra (e.g. the Flask app / CI-CD stack) runs in:

##### \- `AWS/Billing` metrics are only published in us-east-1, account-wide

##### \- This trail's home region is us-east-1

##### 

##### \## Structure

##### 

##### | File | Contents |

##### |---|---|

##### | `providers.tf` | Terraform + AWS provider config |

##### | `variables.tf` | Input variables (region, trail name, bucket name, alert email, billing threshold) |

##### | `locals.tf` | Account ID lookup (`aws\_caller\_identity`) + derived trail ARN |

##### | `s3.tf` | Log bucket, versioning, encryption, bucket policy |

##### | `cloudtrail.tf` | Trail, CloudWatch Logs group, IAM role + managed policy for log delivery |

##### | `metric\_filters.tf` | The three CloudWatch Logs metric filters |

##### | `sns\_and\_alarms.tf` | SNS topic/subscription + all four alarms |

##### | `IMPORT.md` | Step-by-step `terraform import` commands used to adopt the pre-existing resources into state |

##### 

##### \## Usage

##### 

##### ```bash

##### terraform init

##### ```

##### 

##### Create a `terraform.tfvars` (gitignored — never commit real values):

##### 

##### ```hcl

##### cloudtrail\_bucket\_name = "<your-cloudtrail-log-bucket-name>"

##### billing\_alert\_email    = "<your-email>"

##### ```

##### 

##### ```bash

##### terraform plan

##### terraform apply

##### ```

##### 

##### Since the account ID is resolved dynamically via `data.aws\_caller\_identity`,

##### this module is portable to a fresh AWS account as-is — just supply a new,

##### globally-unique `cloudtrail\_bucket\_name` and your own alert email.

##### 

##### \## Known accepted state

##### 

##### \- S3 bucket versioning is intentionally left \*\*disabled\*\* to match the

##### &#x20; existing resource on import. Flagged as a future hardening candidate

##### &#x20; (would protect CloudTrail logs from accidental/malicious deletion) —

##### &#x20; not yet implemented so `terraform plan` stays a clean diff against reality.

##### 

##### \## History

##### 

##### Originally built by hand via the AWS console as part of Phase 3 of a

##### self-directed cloud security study plan. This module retroactively

##### codifies that setup into Terraform so the monitoring stack is reproducible,

##### version-controlled, and drift-detectable going forward.

