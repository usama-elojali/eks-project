#--------------------------------------------------------------
# Dev Environment Configuration
#--------------------------------------------------------------

# Environment
aws_region   = "us-east-1"
environment  = "dev"
project_name = "eks-project"

# VPC
vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]

# EKS
cluster_name    = "eks-cluster"
cluster_version = "1.29"

# Route53
domain_name = "elojali-devops.com"