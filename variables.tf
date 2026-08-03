variable "aws_region" {
  description = "Region for CloudTrail home region + billing metrics (must stay us-east-1 for AWS/Billing metrics)"
  type        = string
  default     = "us-east-1"
}

variable "trail_name" {
  description = "CloudTrail trail name"
  type        = string
  default     = "my-cloudtrail"
}

variable "cloudtrail_bucket_name" {
  description = "S3 bucket name for CloudTrail logs (must be globally unique)"
  type        = string
}

variable "billing_alert_email" {
  description = "Email address to receive billing/security alarm notifications"
  type        = string
}

variable "billing_threshold_usd" {
  description = "Billing alarm threshold in USD"
  type        = number
  default     = 1
}