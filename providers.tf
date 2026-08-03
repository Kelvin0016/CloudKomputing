terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# NOTE: CloudTrail's home region and AWS/Billing metrics both live in
# us-east-1 regardless of where you normally operate (ap-southeast-5).
# This entire module targets us-east-1 on purpose.
provider "aws" {
  region = var.aws_region
}
