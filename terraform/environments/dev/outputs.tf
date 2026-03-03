#--------------------------------------------------------------
# VPC Outputs
#--------------------------------------------------------------

output "vpc_id" {
  description = "The VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

#--------------------------------------------------------------
# Route53 Outputs
#--------------------------------------------------------------

output "route53_zone_id" {
  description = "Route53 hosted zone ID"
  value       = module.route53.zone_id
}

output "route53_name_servers" {
  description = "Route53 nameservers - configure these in Namecheap"
  value       = module.route53.name_servers
}

output "domain_name" {
  description = "Domain name"
  value       = module.route53.domain_name
}

#--------------------------------------------------------------
# EKS Outputs
#--------------------------------------------------------------

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "EKS cluster CA certificate"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "external_dns_role_arn" {
  description = "IAM role ARN for ExternalDNS - use in Helm values"
  value       = module.eks.external_dns_role_arn
}

output "aws_lb_controller_role_arn" {
  description = "IAM role ARN for AWS LB Controller - use in Helm values"
  value       = module.eks.aws_lb_controller_role_arn
}