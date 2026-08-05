run "no_full_port_range_open_to_world" {
  command = plan

  # Generic catch-all: even if someone adds a brand new ingress rule later,
  # this guards against the worst case - a rule spanning the entire port
  # range (0-65535) exposed to 0.0.0.0/0. Doesn't replace the specific
  # port checks above, just backstops anything they don't cover.
  assert {
    condition = alltrue([
      for rule in aws_security_group.docker_host_sg.ingress :
      !(rule.from_port == 0 && rule.to_port == 65535 && contains(rule.cidr_blocks, "0.0.0.0/0"))
    ])
    error_message = "No ingress rule should open the full port range (0-65535) to 0.0.0.0/0"
  }
}
