# Infrastructure Components

## Deployment Order

These components must be deployed in order after EKS cluster is created:

1. **AWS Load Balancer Controller** - Creates ALB/NLB from Kubernetes resources
2. **NGINX Ingress Controller** - Routes traffic to applications
3. **CertManager** - Manages SSL/TLS certificates
4. **ExternalDNS** - Updates Route 53 DNS records
5. **ArgoCD** - GitOps continuous delivery

---

## 1. AWS Load Balancer Controller

### Prerequisites
- EKS cluster running
- IAM role for service account (IRSA) created by Terraform
- Update `values.yaml` with:
  - `clusterName`
  - `serviceAccount.annotations.eks.amazonaws.com/role-arn`
  - `vpcId`

### Install Command
```bash
helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  -f k8s-manifests/infrastructure/aws-load-balancer-controller/values.yaml
```

---

## 2. NGINX Ingress Controller

### Install Command
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx \
  -n ingress-nginx \
  --create-namespace \
  -f k8s-manifests/infrastructure/ingress-nginx/values.yaml
```

### Verify ALB Created
```bash
kubectl get svc -n ingress-nginx
# Should show EXTERNAL-IP with ALB DNS name
```

---

## Why ClusterIP Instead of LoadBalancer for Apps?

| Approach | Cost | When to Use |
|----------|------|-------------|
| LoadBalancer per app | ~$16/month each | Direct external access needed |
| ClusterIP + Ingress | ~$16/month total | Multiple apps, single entry point |

We use **ClusterIP + Ingress** because:
- Single ALB for all apps (cost savings)
- Centralized routing rules
- Easier SSL/TLS management
- Better traffic control

---

## GitOps Workflow with ArgoCD

### How It Works

```
Developer → git push → GitHub → ArgoCD (polls every 3 min) → Kubernetes Cluster
```

### ArgoCD Access

- **URL:** https://argocd.elojali-devops.com
- **Username:** admin
- **Password:** `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`

### Managed Applications

| Application | Git Path | Namespace | Sync Policy |
|-------------|----------|-----------|-------------|
| game-2048 | `k8s-manifests/apps/2048` | default | Auto (Self-Heal) |

### Making Changes

1. Edit manifests in `k8s-manifests/apps/`
2. Commit and push to `main` branch
3. ArgoCD detects change within 3 minutes (or click Refresh in UI)
4. Changes auto-deploy to cluster

### Manual Sync

If auto-sync is disabled or you want immediate deployment:

```bash
argocd app sync game-2048
```

Or use the ArgoCD UI → Click application → SYNC

### Destroy Sequence

When destroying infrastructure, follow this order to avoid orphaned resources:

```bash
# 1. Delete apps (removes Ingress, DNS records, certificates)
kubectl delete -f k8s-manifests/apps/2048/

# 2. Uninstall Helm releases
helm uninstall argocd -n argocd
helm uninstall cert-manager -n cert-manager
helm uninstall external-dns -n external-dns
helm uninstall ingress-nginx -n ingress-nginx
helm uninstall aws-load-balancer-controller -n kube-system

# 3. Wait 2-3 minutes for AWS to release resources

# 4. Terraform destroy
cd terraform/environments/dev
terraform destroy
```
