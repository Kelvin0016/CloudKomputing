resource "aws_cloudtrail" "main" {
  name           = "my-cloudtrail"
  s3_bucket_name = aws_s3_bucket.cloudtrail_logs.id

  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  is_organization_trail         = false

  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_cloudwatch.arn

  advanced_event_selector {
    name = "Management events selector"

    field_selector {
      field  = "eventCategory"
      equals = ["Management"]
    }
  }

  depends_on = [aws_s3_bucket_policy.cloudtrail_logs]
}

resource "aws_cloudwatch_log_group" "cloudtrail" {
  name = "aws-cloudtrail-logs"
}

# Matches the existing service-role/CloudTrail-CloudWatch-Role
resource "aws_iam_role" "cloudtrail_cloudwatch" {
  name = "CloudTrail-CloudWatch-Role"
  path = "/service-role/"
  description = "Role for config CloudWathLogs for trail my-cloudtrail"


  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "sts:AssumeRole"
	Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
            "aws:SourceArn"     = local.cloudtrail_arn
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "cloudtrail_cloudwatch" {
  name = "Cloudtrail-CW-access-policy-my-cloudtrail-1744e639-45c7-4ace-bc11-0a17d838e090"
  path = "/service-role/"
  description = "Policy for config CloudWathLogs for trail my-cloudtrail, created by CloudTrail console"


  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailCreateLogStream2014110"
        Effect = "Allow"
        Action = ["logs:CreateLogStream"]
        Resource = [
          "arn:aws:logs:us-east-1:${data.aws_caller_identity.current.account_id}:log-group:aws-cloudtrail-logs:log-stream:${data.aws_caller_identity.current.account_id}_CloudTrail_us-east-1*"
        ]
      },
      {
        Sid    = "AWSCloudTrailPutLogEvents20141101"
        Effect = "Allow"
        Action = ["logs:PutLogEvents"]
        Resource = [
          "arn:aws:logs:us-east-1:${data.aws_caller_identity.current.account_id}:log-group:aws-cloudtrail-logs:log-stream:${data.aws_caller_identity.current.account_id}_CloudTrail_us-east-1*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudtrail_cloudwatch" {
  role       = aws_iam_role.cloudtrail_cloudwatch.name
  policy_arn = aws_iam_policy.cloudtrail_cloudwatch.arn
}