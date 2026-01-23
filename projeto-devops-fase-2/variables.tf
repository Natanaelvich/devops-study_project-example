variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod"
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "website"
}

variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
  sensitive   = true
}

variable "ssh_allowed_ip" {
  description = "IP address allowed to SSH into the EC2 instance (CIDR format)"
  type        = string
  sensitive   = true
  default     = "0.0.0.0/0" # Change this to your IP for security
}

variable "key_pair_name" {
  description = "Name of the AWS Key Pair for EC2 instance access"
  type        = string
  sensitive   = true
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "client_name" {
  description = "Client name for tagging resources"
  type        = string
  default     = "Default"
}

variable "terraform_state_bucket" {
  description = "S3 bucket name for Terraform state"
  type        = string
  sensitive   = true
}

variable "terraform_state_key" {
  description = "S3 key path for Terraform state"
  type        = string
  default     = "site/terraform.tfstate"
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "site_prod"
}

variable "security_group_name" {
  description = "Name of the security group"
  type        = string
  default     = ""
}

variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
  default     = ""
}

variable "iam_role_name" {
  description = "Name of the IAM role for EC2"
  type        = string
  default     = ""
}
