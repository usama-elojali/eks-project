# Infrastructure Components

## Deployment Order

These components must be deployed in order after EKS cluster is created:

1. **AWS Load Balancer Controller** - Creates ALB/NLB from Kubernetes resources
2. **NGINX Ingress Controller** - Routes traffic to applications
3. **CertManager** - Manages SSL/TLS certificates (future ticket)
4. **ExternalDNS** - Updates Route 53 DNS records (future ticket)

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

