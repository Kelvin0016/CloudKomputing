resource "aws_sns_topic" "billing_alert" {
  name = "billing-alert"
}

resource "aws_sns_topic_subscription" "billing_alert_email" {
  topic_arn = aws_sns_topic.billing_alert.arn
  protocol  = "email"
  endpoint  = var.billing_alert_email

  # NOTE: email subscriptions require manual confirmation via the inbox link.
  # Terraform will create the subscription in "PendingConfirmation" state;
  # confirming it is a one-time manual step, same as the original setup.
}

resource "aws_cloudwatch_metric_alarm" "billing" {
  alarm_name          = "billing-alert"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods   = 1
  datapoints_to_alarm  = 1
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = 21600
  statistic           = "Maximum"
  threshold           = 1
  treat_missing_data  = "missing"

  dimensions = {
    Currency = "USD"
  }

  alarm_actions = [aws_sns_topic.billing_alert.arn]
}

resource "aws_cloudwatch_metric_alarm" "iam_policy_changes" {
  alarm_name          = "IAMPolicyChanges-Alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods   = 1
  datapoints_to_alarm  = 1
  metric_name         = aws_cloudwatch_log_metric_filter.iam_policy_changes.metric_transformation[0].name
  namespace           = aws_cloudwatch_log_metric_filter.iam_policy_changes.metric_transformation[0].namespace
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "missing"

  alarm_actions = [aws_sns_topic.billing_alert.arn]
}

resource "aws_cloudwatch_metric_alarm" "root_account_login" {
  alarm_name          = "RootAccountLogin-Alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods   = 1
  datapoints_to_alarm  = 1
  metric_name         = aws_cloudwatch_log_metric_filter.root_account_login.metric_transformation[0].name
  namespace           = aws_cloudwatch_log_metric_filter.root_account_login.metric_transformation[0].namespace
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "missing"

  alarm_actions = [aws_sns_topic.billing_alert.arn]
}

resource "aws_cloudwatch_metric_alarm" "security_group_changes" {
  alarm_name          = "SecurityGroupChanges-Alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods   = 1
  datapoints_to_alarm  = 1
  metric_name         = aws_cloudwatch_log_metric_filter.security_group_changes.metric_transformation[0].name
  namespace           = aws_cloudwatch_log_metric_filter.security_group_changes.metric_transformation[0].namespace
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "missing"

  alarm_actions = [aws_sns_topic.billing_alert.arn]
}
