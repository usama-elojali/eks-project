#--------------------------------------------------------------
# VPC Module
#--------------------------------------------------------------

module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr             = var.vpc_cidr
  environment          = var.environment
  project_name         = var.project_name
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  cluster_name         = var.cluster_name
}

#--------------------------------------------------------------
# Route53 Module
#--------------------------------------------------------------

module "route53" {
  source = "../../modules/route53"

  domain_name = var.domain_name

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

#--------------------------------------------------------------
# EKS Module
#--------------------------------------------------------------

module "eks" {
  source = "../../modules/eks"

  cluster_name       = var.cluster_name
  kubernetes_version = var.cluster_version

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids

  environment  = var.environment
  project_name = var.project_name
}# Trigger CI test
# Trigger CI test
