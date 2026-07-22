# Generate a new SSH key pair
resource "tls_private_key" "docker_host_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "docker_host_key" {
  key_name   = "docker-study-key-my5"
  public_key = tls_private_key.docker_host_key.public_key_openssh
}

# Save the private key locally so you can SSH in
resource "local_file" "private_key" {
  content         = tls_private_key.docker_host_key.private_key_pem
  filename        = "${path.module}/docker-study-key-my5.pem"
  file_permission = "0400"
}

# Look up the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "docker_host" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.docker_host_key.key_name
  vpc_security_group_ids = [aws_security_group.docker_host_sg.id]

user_data = <<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y docker
    systemctl enable --now docker
    usermod -aG docker ec2-user
  EOF

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = {
    Name = "docker-study-host"
  }
# Once created, don't replace the instance just because AWS published a
  # newer AMI. Only change the AMI (and thus the instance) intentionally.
  lifecycle {
    ignore_changes = [ami]
  }

}

output "instance_public_ip" {
  value = aws_instance.docker_host.public_ip
}

output "instance_id" {
  value = aws_instance.docker_host.id
}

output "ssh_command" {
  value = "ssh -i docker-study-key-my5.pem ec2-user@${aws_instance.docker_host.public_ip}"
}
