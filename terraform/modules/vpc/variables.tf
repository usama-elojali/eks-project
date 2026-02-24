## CORE VARIABLES
variable "cidr_block" {
  type = string
}

variable "tags" {
  type = map(string)
}

## SUBNET VARIABLE

variable "public_subnet_cidrs" {
  type = list(string)

  validation {
    condition     = length(var.public_subnet_cidrs) == length(var.azs) && length(var.public_subnet_cidrs) > 0
    error_message = "Public subnet count must match AZ count."
  }
}

variable "private_subnet_cidrs" {
  type = list(string)

  validation {
    condition     = length(var.private_subnet_cidrs) == length(var.azs) && length(var.private_subnet_cidrs) > 0
    error_message = "Private subnet count must match AZ count."
  }
}

variable "azs" {
  type = list(string)
}

## NAT CONFIGURATION VARIABLE

variable "enable_nat_gateway" {
  type    = bool
  default = false
}

variable "single_nat_gateway" {
  type    = bool
  default = true
}

variable "cluster_name" {
  type = string
}