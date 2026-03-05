#!/bin/bash
#
# EKS Project Destroy Script
# ==========================
#
# WHY THIS SCRIPT EXISTS:
# -----------------------
# Kubernetes controllers (ExternalDNS, AWS LB Controller) create AWS resources
# (Route53 records, Load Balancers, Security Groups) that Terraform doesn't know about.
#
# If you run `terraform destroy` directly:
#   1. Terraform tries to delete VPC
#   2. VPC has dependencies (DNS records, Load Balancers) that Terraform didn't create
#   3. Terraform fails with "DependencyViolation"
#   4. You have to manually clean up orphaned resources
#
# THE CORRECT ORDER:
# ------------------
# 1. Delete Ingresses FIRST (while ExternalDNS is still running)
#    → ExternalDNS sees Ingress deleted → removes Route53 records
# 2. THEN uninstall Helm releases (ExternalDNS, LB Controller, etc.)
# 3. THEN run terraform destroy (VPC now has no dependencies)
#
# COMMON MISTAKES:
# ----------------
# ❌ Running `terraform destroy` directly
# ❌ Uninstalling ExternalDNS BEFORE deleting Ingresses
# ❌ Only deleting app Ingresses but forgetting ArgoCD Ingress
#
# USAGE:
# ------
# cd eks-project
# ./scripts/destroy.sh
#
set -e

echo "=============================================="
echo "EKS Project Destroy Script"
echo "=============================================="
echo ""

# -----------------------------------------------------------------------------
# STEP 1: Delete ALL Ingress resources
# -----------------------------------------------------------------------------
# WHY: Ingresses have annotations that tell ExternalDNS to create DNS records.
#      When we delete the Ingress, ExternalDNS sees this and REMOVES the DNS record.
#      But ExternalDNS must still be running for this to work!
#
# CRITICAL: This must happen BEFORE uninstalling ExternalDNS
# -----------------------------------------------------------------------------
echo "=== Step 1: Delete ALL Ingress resources ==="
echo "This triggers ExternalDNS to clean up Route53 records."
echo "ExternalDNS must still be running for this to work!"
kubectl delete ingress --all -A --ignore-not-found
echo "Waiting 30 seconds for ExternalDNS to delete DNS records..."
sleep 30

# -----------------------------------------------------------------------------
# STEP 2: Delete app manifests (cleanup)
# -----------------------------------------------------------------------------
# WHY: Good hygiene. The Ingress is already deleted from Step 1, but this
#      removes Deployments, Services, etc. Not strictly necessary but cleaner.
# -----------------------------------------------------------------------------
echo "=== Step 2: Delete app manifests ==="
kubectl delete -f k8s-manifests/apps/2048/ --ignore-not-found 2>/dev/null || true

# -----------------------------------------------------------------------------
# STEP 3: Uninstall Helm releases
# -----------------------------------------------------------------------------
# WHY: These controllers created AWS resources (Load Balancers, Security Groups).
#      Uninstalling them triggers cleanup of those resources.
#
# ORDER MATTERS:
#   - ArgoCD first (it's just an app, no AWS resources)
#   - CertManager (manages certificates)
#   - ExternalDNS (NOW safe to remove - Ingresses already deleted)
#   - NGINX Ingress (removes the ALB)
#   - AWS LB Controller last (it manages the ALB lifecycle)
# -----------------------------------------------------------------------------
echo "=== Step 3: Uninstall Helm releases ==="
helm uninstall argocd -n argocd 2>/dev/null || true
helm uninstall cert-manager -n cert-manager 2>/dev/null || true
helm uninstall external-dns -n external-dns 2>/dev/null || true
helm uninstall ingress-nginx -n ingress-nginx 2>/dev/null || true
helm uninstall aws-load-balancer-controller -n kube-system 2>/dev/null || true

# -----------------------------------------------------------------------------
# STEP 4: Wait for AWS to release resources
# -----------------------------------------------------------------------------
# WHY: AWS takes time to fully delete Load Balancers, release ENIs, and
#      disassociate Security Groups. If we run terraform destroy too soon,
#      the VPC will still have dependencies.
#
# 3 minutes is usually enough. Increase if you still get dependency errors.
# -----------------------------------------------------------------------------
echo "=== Step 4: Wait for AWS to release resources ==="
echo "Waiting 3 minutes for AWS to fully release Load Balancers, ENIs, etc..."
sleep 180

# -----------------------------------------------------------------------------
# STEP 5: Terraform destroy
# -----------------------------------------------------------------------------
# WHY: NOW it's safe to destroy. The VPC should have no external dependencies.
# -----------------------------------------------------------------------------
echo "=== Step 5: Terraform destroy ==="
cd terraform/environments/dev
terraform destroy -auto-approve

# -----------------------------------------------------------------------------
# STEP 6: Reset VPC ID in values.yaml
# -----------------------------------------------------------------------------
# WHY: The VPC ID in values.yaml is now stale (that VPC no longer exists).
#      Setting it to a placeholder ensures you get an obvious error if you
#      forget to update it after the next `terraform apply`.
# -----------------------------------------------------------------------------
echo "=== Step 6: Reset VPC ID in values.yaml ==="
cd ../../..
sed -i '' 's/vpcId: vpc-[a-z0-9]*/vpcId: UPDATE_AFTER_TERRAFORM_APPLY/' k8s-manifests/infrastructure/aws-load-balancer-controller/values.yaml
echo "VPC ID reset to placeholder."

# -----------------------------------------------------------------------------
# DONE
# -----------------------------------------------------------------------------
echo ""
echo "=============================================="
echo "Destroy Complete!"
echo "=============================================="
echo ""
echo "Next time you spin up infrastructure:"
echo "  1. cd eks-project/terraform/environments/dev"
echo "  2. terraform apply"
echo "  3. terraform output vpc_id"
echo "  4. Update vpcId in k8s-manifests/infrastructure/aws-load-balancer-controller/values.yaml"
echo ""