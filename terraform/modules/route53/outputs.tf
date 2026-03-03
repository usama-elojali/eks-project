#--------------------------------------------------------------
# Route53 Module Outputs
#--------------------------------------------------------------

output "zone_id" {
  description = "The hosted zone ID"
  value       = aws_route53_zone.main.zone_id
}

output "zone_arn" {
  description = "The hosted zone ARN"
  value       = aws_route53_zone.main.arn
}

output "name_servers" {
  description = "The nameservers for the hosted zone - configure these in Namecheap"
  value       = aws_route53_zone.main.name_servers
}

output "domain_name" {
  description = "The domain name"
  value       = aws_route53_zone.main.name
}