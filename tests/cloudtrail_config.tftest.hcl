run "cloudtrail_stays_multi_region_and_validated" {
  command = plan

  # Ties back to the monitoring-tf module finished last session - guards
  # against someone narrowing the trail to a single region (which would
  # blind CloudTrail to activity in other regions) or disabling log file
  # validation (which protects against tampering with delivered logs).
  assert {
    condition     = aws_cloudtrail.main.is_multi_region_trail == true
    error_message = "CloudTrail must stay multi-region - narrowing this would blind logging to activity outside us-east-1"
  }

  assert {
    condition     = aws_cloudtrail.main.enable_log_file_validation == true
    error_message = "CloudTrail log file validation must stay enabled to detect tampering with delivered logs"
  }

  assert {
    condition     = aws_cloudtrail.main.include_global_service_events == true
    error_message = "CloudTrail must keep capturing global service events (e.g. IAM), not just regional ones"
  }
}
