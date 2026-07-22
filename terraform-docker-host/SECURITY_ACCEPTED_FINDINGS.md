# Trivy Scan — Accepted Findings

Scan run: `trivy config .` against terraform-docker-host, 2026-07-22.
2 of 4 original findings fixed (see ec2.tf: IMDSv2 enforced, root volume encrypted).
The following 2 findings are consciously accepted, not fixed, with reasoning below.

---

## AWS-0066 (LOW) — Lambda function does not have X-Ray tracing enabled
**File:** lambda.tf — aws_lambda_function.ec2_auto_stop

**Accepted because:** This Lambda runs a 3-line runtime check every 15 minutes
(describe instance, compare launch time, stop if over 4 hours). It is not
business-critical, has no complex call chain, and any failure is immediately
visible via CloudWatch Logs without needing distributed tracing. X-Ray adds
cost and complexity disproportionate to the value for a function this simple.

**Would reconsider if:** the function grew to call multiple downstream
services, or if silent failures became a real operational problem.

---

## AWS-0104 (CRITICAL) — Security group allows unrestricted egress (0.0.0.0/0)
**File:** security_group.tf — aws_security_group.docker_host_sg

**Accepted because:** This instance is a Docker development host that needs
outbound access to pull images from Docker Hub, install OS packages via dnf,
and reach GitHub for the CI/CD pipeline. These destinations use dynamic,
frequently-changing IP ranges that are impractical to enumerate and maintain
in a security group. Restricting egress would require a NAT/proxy allowlist
setup disproportionate to a single-instance personal study environment.

Ingress remains tightly restricted (SSH only, locked to the caller's current
IP, refreshed on every terraform apply) — the actual exploitable attack
surface (inbound) is minimal. Unrestricted egress is a common, defensible
exception for dev/build hosts, distinct from production workloads handling
sensitive data, where egress restriction would be justified.

**Would reconsider if:** this instance ever handled production traffic or
sensitive data, or if it were part of a larger environment where lateral
movement via egress became a realistic threat model.
