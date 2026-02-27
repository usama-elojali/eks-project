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

## Project Tasks

### 1. AWS Infrastructure Setup (Terraform)
- Create an EKS cluster, VPC, IAM roles, and security groups using Terraform
- Use reusable Terraform modules for infrastructure components
- Ensure proper state management is in place
- Configure networking with private subnets for the EKS cluster and public subnets for load balancing
- Define IAM roles for the Kubernetes worker nodes and ensure security groups limit access to only required resources

### 2. NGINX Ingress Controller
- Deploy and configure the NGINX Ingress Controller on the EKS cluster using Helm charts or Kubernetes manifests
- Configure the controller to route incoming traffic to the correct Kubernetes services
- Set up rules for HTTPS using TLS certificates managed by CertManager

### 3. CertManager (SSL/TLS Management)
- Install and configure CertManager on the cluster
- Set up Let's Encrypt or a custom CA to generate SSL certificates automatically for the application
- Integrate the certificates with the NGINX Ingress Controller for secure HTTPS connections

### 4. Dynamic DNS Updates (ExternalDNS)
- Deploy ExternalDNS on the EKS cluster to automate DNS record management
- Configure ExternalDNS to dynamically update DNS records in Route 53 based on changes in Kubernetes ingress resources
- Ensure the DNS updates reflect the public endpoint of the application when services or ingresses change

### 5. CI/CD Pipeline 1: Terraform
- Automate Terraform deployments for provisioning EKS and related AWS resources
- Integrate state management using a remote backend (e.g., S3 + DynamoDB)
- Include error handling and proper validation of Terraform code before deployments

### 6. CI/CD Pipeline 2: Docker, Security, and Kubernetes
- Scan the Terraform code using Checkov to catch misconfigurations and ensure compliance with security best practices
- Build and push the Docker image of your application to Amazon ECR using the pipeline
- Use Trivy to scan the Docker image for vulnerabilities
- Deploy the application to EKS using Kubernetes manifests or Helm charts

### 7. GitOps with ArgoCD
- Set up ArgoCD to automate the deployment of Kubernetes manifests from your Git repository to the EKS cluster
- Ensure the deployment is triggered automatically when changes are pushed to the repo
- Create a GitOps workflow where the cluster state is reconciled with the desired state defined in the Git repository

### 8. Monitoring and Observability
- Deploy Prometheus to collect metrics from the Kubernetes cluster, including pods, nodes, namespaces, and services
- Set up Grafana to visualize the metrics and create custom dashboards
- Include dashboards showing high CPU/memory usage, pod health, node statuses, and Ingress traffic

### 9. Architecture Documentation
- Create a clear, well-documented architecture diagram using Lucidchart, draw.io, or Mermaid
- The diagram should show:
  - AWS infrastructure (VPC, EKS, subnets, security groups, IAM roles)
  - Traffic flow through the NGINX Ingress Controller
  - Dynamic DNS setup using ExternalDNS
  - Certificate management with CertManager
  - ArgoCD GitOps flow
  - Monitoring components (Prometheus and Grafana)