run "ami_lookup_targets_al2023_x86_64" {
  command = plan

  # Guards against someone loosening the AMI filter later (e.g. dropping
  # the version pin or architecture) and silently picking up an
  # unintended/unvetted image.
  assert {
    condition = anytrue([
      for f in data.aws_ami.amazon_linux_2023.filter :
      f.name == "name" && anytrue([for v in f.values : startswith(v, "al2023-ami-")])
    ])
    error_message = "AMI lookup must stay pinned to Amazon Linux 2023 (al2023-ami-*), not a broader/unrelated image family"
  }

  assert {
    condition = anytrue([
      for f in data.aws_ami.amazon_linux_2023.filter :
      f.name == "name" && anytrue([for v in f.values : endswith(v, "-x86_64")])
    ])
    error_message = "AMI lookup must stay pinned to x86_64 architecture"
  }

  assert {
    condition     = data.aws_ami.amazon_linux_2023.owners[0] == "amazon"
    error_message = "AMI must be owned by Amazon (official image), not a third-party/community AMI"
  }
}
