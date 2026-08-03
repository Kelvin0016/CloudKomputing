resource "aws_cloudwatch_log_metric_filter" "iam_policy_changes" {
  name           = "IAMPolicyChanges"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name

  pattern = "{ ($.eventName = DeleteGroupPolicy) || ($.eventName = DeleteRolePolicy) || ($.eventName = DeleteUserPolicy) || ($.eventName = PutGroupPolicy) || ($.eventName = PutRolePolicy) || ($.eventName = PutUserPolicy) || ($.eventName = CreatePolicy) || ($.eventName = DeletePolicy) || ($.eventName = AttachRolePolicy) || ($.eventName = DetachRolePolicy) }"

  metric_transformation {
    name          = "IAMPolicyChangeCount"
    namespace     = "CloudTrailMetrics"
    value         = "1"
    default_value = "0"
unit = "None"
  }
}

resource "aws_cloudwatch_log_metric_filter" "root_account_login" {
  name           = "RootAccountLogin"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name

  pattern = "{ $.userIdentity.type = \"Root\" && $.eventType != \"AwsServiceEvent\" }"

  metric_transformation {
    name          = "RootAccountLoginCount"
    namespace     = "CloudTrailMetrics"
    value         = "1"
    default_value = "0"
unit = "None"
  }
}

resource "aws_cloudwatch_log_metric_filter" "security_group_changes" {
  name           = "SecurityGroupChanges"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name

  pattern = "{ ($.eventName = AuthorizeSecurityGroupIngress) || ($.eventName = AuthorizeSecurityGroupEgress) || ($.eventName = RevokeSecurityGroupIngress) || ($.eventName = RevokeSecurityGroupEgress) || ($.eventName = CreateSecurityGroup) || ($.eventName = DeleteSecurityGroup) }"

  metric_transformation {
    name          = "SecurityGroupChangeCount"
    namespace     = "CloudTrailMetrics"
    value         = "1"
    default_value = "0"
unit = "None"
  }
}
