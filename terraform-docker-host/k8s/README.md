# k8s/

Kubernetes manifests for running the Flask app on a local `kind` cluster,
deployed on the same EC2 host provisioned by the Terraform config in this
folder (`terraform-docker-host`).

Backed up here from the live EC2 instance (`~/k8s/` there) so they're
version-controlled and recoverable if the instance is ever rebuilt.

## Files

| File | Purpose |
|---|---|
| `kind-config.yaml` | Cluster config for `kind create cluster`. Maps NodePort 30500 out to the host — without this, `kind` doesn't expose NodePorts beyond its internal Docker network. |
| `flask-deployment.yaml` | Deployment — keeps 2 replicas of `flask-app:latest` running, restarting any pod that crashes or gets deleted. |
| `flask-service.yaml` | Service (NodePort) — exposes the Deployment on port 30500, routing traffic to whichever pod replicas are currently healthy. |

## Usage (on the EC2 host)

```bash
# create the cluster with the port mapping
kind create cluster --name flask-cluster --config kind-config.yaml

# load the locally-built Flask image into the cluster
# (kind's node runs in its own isolated Docker context — images aren't
# automatically visible to it just because they exist on the host)
kind load docker-image flask-app:latest --name flask-cluster

# deploy
kubectl apply -f flask-deployment.yaml
kubectl apply -f flask-service.yaml

# verify
kubectl get pods
kubectl get svc

# test
curl localhost:30500
```

## Notes

- Single-node cluster — control plane and workload share the same EC2
  instance and the same fate. This demonstrates pod-level self-healing
  (see below) but **not** resilience to the underlying instance crashing.
  See `kubernetes-fundamentals.md` on `main` for the full writeup, including
  the resource-exhaustion issue hit on `t3.micro` and the fix (temporary
  resize to `t3.small`).
- Self-healing verified: `kubectl delete pod <name>` → Kubernetes
  automatically starts a replacement within ~30s to restore the declared
  replica count.
