# Native `terraform test` (HCL, Terraform 1.6+) — run with:
#   terraform test
# from inside terraform-docker-host/. This runs against the real provider
# by default (command = plan avoids creating anything; only apply-based
# runs actually stand up infra).

run "no_ssh_open_to_world" {
  command = plan

  assert {
    condition = alltrue([
      for rule in aws_security_group.docker_host_sg.ingress :
      !(rule.from_port <= 22 && rule.to_port >= 22 && contains(rule.cidr_blocks, "0.0.0.0/0"))
    ])
    error_message = "SSH (port 22) must not be open to 0.0.0.0/0"
  }
}

run "flask_port_not_open_to_world" {
  command = plan

  assert {
    condition = alltrue([
      for rule in aws_security_group.docker_host_sg.ingress :
      !(rule.from_port <= 5000 && rule.to_port >= 5000 && contains(rule.cidr_blocks, "0.0.0.0/0"))
    ])
    error_message = "Flask app port (5000) must not be open to 0.0.0.0/0 — should stay restricted to my_ip_cidr"
  }
}

run "profile_site_intentionally_public" {
  command = plan

  # Port 8080 (profile site) IS meant to be open to the world — this test
  # documents that as an intentional, verified exception rather than an
  # oversight. If this ever starts failing, someone tightened 8080 without
  # updating this test — worth a second look either way.
  assert {
    condition = anytrue([
      for rule in aws_security_group.docker_host_sg.ingress :
      rule.from_port <= 8080 && rule.to_port >= 8080 && contains(rule.cidr_blocks, "0.0.0.0/0")
    ])
    error_message = "Expected port 8080 (profile site) to be intentionally open to 0.0.0.0/0 — if this changed, update this test to match the new intent"
  }
}

run "ec2_root_volume_encrypted" {
  command = plan

  assert {
    condition     = aws_instance.docker_host.root_block_device[0].encrypted == true
    error_message = "Root EBS volume must be encrypted"
  }
}

run "ec2_imdsv2_enforced" {
  command = plan

  assert {
    condition     = aws_instance.docker_host.metadata_options[0].http_tokens == "required"
    error_message = "IMDSv2 must be enforced (http_tokens = required) to prevent SSRF-based credential theft"
  }
}
