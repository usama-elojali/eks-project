# variables.tf - Input variables for EKS module

#------------------------------------------------------------------------------
# Cluster Configuration
#------------------------------------------------------------------------------

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string

  validation {
    condition     = length(var.cluster_name) > 0 && length(var.cluster_name) <= 100
    error_message = "Cluster name must be between 1 and 100 characters."
  }
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.29"

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+$", var.kubernetes_version))
    error_message = "Kubernetes version must be in format X.XX (e.g., 1.29)."
  }
}

#------------------------------------------------------------------------------
# Environment Configuration
#------------------------------------------------------------------------------

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "project_name" {
  description = "Name of the project (used for tagging)"
  type        = string

  validation {
    condition     = length(var.project_name) > 0 && length(var.project_name) <= 32
    error_message = "Project name must be between 1 and 32 characters."
  }
}

#------------------------------------------------------------------------------
# Network Configuration (from VPC module)
#------------------------------------------------------------------------------

variable "vpc_id" {
  description = "ID of the VPC where EKS will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for worker nodes"
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "At least 2 private subnets are required for high availability."
  }
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for EKS ENIs"
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_ids) >= 2
    error_message = "At least 2 public subnets are required for high availability."
  }
}

#------------------------------------------------------------------------------
# Node Group Configuration
#------------------------------------------------------------------------------

variable "node_instance_types" {
  description = "List of EC2 instance types for worker nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 4
}