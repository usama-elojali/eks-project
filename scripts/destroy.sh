#!/bin/bash
set -e

echo "=== Step 1: Delete Ingress resources (ExternalDNS will clean up DNS) ==="
kubectl delete ingress --all -A --ignore-not-found
echo "Waiting 30 seconds for ExternalDNS to delete DNS records..."
sleep 30

echo "=== Step 2: Delete app manifests ==="
kubectl delete -f k8s-manifests/apps/2048/ --ignore-not-found

echo "=== Step 3: Delete ArgoCD Ingress ==="
kubectl delete -f k8s-manifests/infrastructure/argocd/ingress.yaml --ignore-not-found
sleep 10

echo "=== Step 4: Uninstall Helm releases ==="
helm uninstall argocd -n argocd --ignore-not-found || true
helm uninstall cert-manager -n cert-manager --ignore-not-found || true
helm uninstall external-dns -n external-dns --ignore-not-found || true
helm uninstall ingress-nginx -n ingress-nginx --ignore-not-found || true
helm uninstall aws-load-balancer-controller -n kube-system --ignore-not-found || true

echo "=== Step 5: Wait for AWS to release resources ==="
echo "Waiting 3 minutes..."
sleep 180

echo "=== Step 6: Terraform destroy ==="
cd terraform/environments/dev
terraform destroy -auto-approve

echo "=== Done ==="