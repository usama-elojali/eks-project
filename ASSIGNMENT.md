# EKS Assignment

## Goal
Deploy a cloud-native application on Amazon EKS accessible via HTTPS at:
`https://eks.elojali-devops.com`

## Evaluation Criteria

| Category | Points |
|----------|--------|
| Board / Tickets | 10 |
| Terraform for AWS Infra | 15 |
| NGINX Ingress Controller | 10 |
| CertManager & ExternalDNS | 20 |
| Monitoring Setup | 15 |
| Pipeline 1: Terraform | 10 |
| Pipeline 2: Security, Docker | 30 |
| ArgoCD (GitOps) | 15 |
| Architecture Design | 10 |
| **Total** | **135** |

## Tasks
1. AWS Infrastructure Setup (Terraform) - EKS, VPC, IAM, Security Groups
2. NGINX Ingress Controller - Route traffic, HTTPS rules
3. CertManager - SSL/TLS with Let's Encrypt
4. ExternalDNS - Auto-update Route53
5. CI/CD Pipeline 1 - Terraform automation
6. CI/CD Pipeline 2 - Checkov, Trivy, Docker, Deploy
7. ArgoCD - GitOps automated deployments
8. Monitoring - Prometheus & Grafana dashboards
9. Architecture Documentation - Diagrams showing full flow