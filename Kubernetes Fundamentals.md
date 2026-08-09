# Kubernetes Fundamentals — kind + Flask App

Part of the self-directed cloud security study plan, following the retroactive
Terraform monitoring module and the `terraform test` infrastructure testing
work. This branch covers container orchestration basics using `kind`
(Kubernetes in Docker), deployed on the existing `terraform-docker-host` EC2
instance alongside the Dockerized Flask app.

## Purpose

Docker alone runs one container at a time — if it crashes, it stays down
until someone manually restarts it (a gotcha already hit earlier in this
plan: "containers don't auto-restart after instance stop/start"). Kubernetes
solves that class of problem by letting you declare *desired state*
("2 replicas of this app, always") and continuously reconciling reality to
match it — restarting crashed containers, rescheduling them elsewhere if a
node dies, and load-balancing traffic across whichever replicas are healthy.

The goal of this exercise was to get hands-on with that model — not to run
Kubernetes in production, but to understand what it actually does underneath
the abstraction, using the existing Flask app as a real (if small) workload.

## What was set up

- **Tools installed on the EC2 host:** `kubectl` (v1.36.3) and `kind`
  (v0.23.0) — no extra cost, runs entirely inside the Docker already present
  on the instance from Phase 5.
- **Cluster:** a single-node `kind` cluster named `flask-cluster` — the one
  node acts as both control plane and worker, which is normal for local/dev
  use but explicitly *not* how production clusters are structured (see
  "Limitations" below).
- **Deployment (`flask-deployment.yaml`):** runs 2 replicas of the existing
  `flask-app:latest` image, loaded into the cluster via `kind load
  docker-image` (kind's nodes run in their own container, isolated from the
  host's normal Docker daemon, so images have to be explicitly loaded in —
  they don't automatically inherit whatever's already built on the host).
- **Service (`flask-app-service.yaml`):** a `NodePort` service exposing the
  app on port 30500, giving one stable address that routes to whichever pod
  replicas are currently healthy.
- **`kind-config.yaml`:** a cluster config mapping the NodePort out to the
  actual EC2 host — by default `kind` does *not* expose NodePorts to the
  host machine, only the Kubernetes API port. This had to be created
  explicitly and the cluster recreated with it for `curl localhost:30500`
  to work at all.

## What actually happened

### Resource exhaustion on t3.micro
Running `kind`'s full control plane (`etcd`, `kube-apiserver`,
`kube-controller-manager`, `kubelet`, CoreDNS, a storage provisioner)
alongside the existing Flask container pushed the `t3.micro` instance (1GB
RAM, 2 vCPU) past its limits. `kind load docker-image` hung for 15+ minutes;
`top` showed a load average of 14 (healthy would be under 2) and 83% I/O
wait, with only ~60MB RAM free and no swap configured. Root cause: the
control plane alone is fairly heavy for a micro instance, and adding
existing Docker workloads on top of it left almost nothing free.

**Fix:** temporarily resized the instance to `t3.small` (2GB RAM) via
`aws ec2 modify-instance-attribute`, which requires a stop → modify → start
cycle. Confirmed load dropped from 14 to under 5 and the stuck operation
completed shortly after. Resized back to `t3.micro` once the session's
Kubernetes work was done, to keep ongoing cost low.

### A region-mismatch incident (found and fixed mid-session)
Unrelated to Kubernetes directly, but surfaced while restarting the EC2 host
for this work: an earlier fix to `provider.tf` (removing a hardcoded local
AWS profile so `terraform test` would work in CI) had accidentally dropped
the entire `provider "aws" {}` block, including the `region` setting.
Terraform silently fell back to the AWS config file's default region
(`ap-southeast-1`, Singapore) instead of the real `ap-southeast-5`
(Malaysia). A `terraform apply` run during this session created a duplicate
instance, security group, and key pair in the wrong region while the real
resources sat untouched in `ap-southeast-5` — briefly running two live EC2
instances without either being fully aware of the other.

**Fix:** restored `provider "aws" { region = "ap-southeast-5" }` (still
without the hardcoded profile, keeping CI compatibility), terminated the
stray Singapore resources, and used `terraform state rm` +
`terraform import` to re-point Terraform's state at the real, correct
resources. `terraform plan` came back clean afterward, aside from expected
IP/ARN drift.

### NodePort not reachable by default
After the first successful deployment, `curl localhost:30500` on the EC2
host failed to connect even though the pods were running and healthy. Root
cause: `kind` runs its "node" as an isolated Docker container, and only
publishes the Kubernetes API port to the host by default — NodePorts aren't
automatically exposed. Fixed by deleting and recreating the cluster with an
explicit `extraPortMappings` entry in `kind-config.yaml`, mapping
containerPort 30500 to hostPort 30500. Confirmed working immediately after.

### Self-healing, demonstrated live
With the cluster fully working, manually deleted one of the two running
pods (`kubectl delete pod <name>`) to observe Kubernetes' reconciliation
behavior directly. Within ~30 seconds, a replacement pod appeared
automatically and the Deployment returned to `2/2` — no manual restart, no
CI trigger, nothing beyond the delete itself. This is the concrete version
of "declare desired state, Kubernetes maintains it," verified hands-on
rather than just read about.

## Key concepts reinforced

- **Declarative vs. imperative**: Deployments describe *what should be
  true* (N replicas of image X); Kubernetes continuously reconciles reality
  toward that, rather than requiring step-by-step manual commands the way
  plain `docker run` does.
- **Pod-level vs. node-level resilience are different problems.** This
  single-node cluster only demonstrates pod-level self-healing (a crashed
  *container* gets replaced). It does **not** protect against the
  underlying EC2 instance itself crashing — if the one node dies, the
  control plane dies with it, and there's nothing left to do the healing.
  Real node-level resilience requires multiple nodes, so pods can be
  rescheduled onto surviving machines if one goes down.
- **Services abstract away "which pod, which server."** Callers hit one
  stable address; Kubernetes handles routing to whichever healthy replica
  is currently available, and updates that routing continuously as pods
  come and go — no caller-side awareness of individual pod IPs needed.
- **Manual intervention is still possible and normal** (`kubectl cordon`,
  `kubectl drain`, node affinity/taints), but the design intent nudges
  toward "run redundant replicas and let the scheduler handle failures,"
  not "manually route around a specific failing server."

## Limitations of this setup (by design, for learning)

- Single node — control plane and workload share the same machine and the
  same fate. No protection against a full EC2 instance crash.
- Not production-representative for scaling/HA behavior — real clusters
  (e.g. EKS) separate the control plane (AWS-managed, replicated across
  availability zones) from worker nodes (multiple, independently
  replaceable via Auto Scaling Groups).
- No persistent storage, ingress controller, or resource limits configured
  yet — kept intentionally minimal to focus on the core Deployment/Service/
  self-healing loop first.

## Next steps

- Try `kubectl scale deployment flask-app --replicas=4` to see live scaling
- Rolling update demo (push a new image, watch pods replace gradually with
  no downtime, vs. the current CI/CD pipeline's stop-then-start approach)
- Eventually: EKS, once ready to spend a small, time-boxed amount of AWS
  credit on a managed cluster with real multi-node resilience
