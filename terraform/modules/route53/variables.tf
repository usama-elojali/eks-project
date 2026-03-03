#--------------------------------------------------------------
# Route53 Module Variables
#--------------------------------------------------------------

variable "domain_name" {
  description = "The domain name for the hosted zone (e.g., elojali-devops.com)"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}