variable "name" {
  description = "Name tag for the EC2 instance"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_pair_name" {
  description = "Name of the AWS Key Pair for EC2 instance access"
  type        = string
  sensitive   = true
}

variable "subnet_id" {
  description = "Subnet ID to launch the instance in (optional; if not set, uses default subnet in VPC)"
  type        = string
  default     = null
}

variable "associate_public_ip_address" {
  description = "Whether to associate a public IP address with the instance (optional; useful in custom VPCs)"
  type        = bool
  default     = null
}

variable "security_group_ids" {
  description = "List of security group IDs to attach to the instance"
  type        = list(string)
}

variable "iam_instance_profile_name" {
  description = "Name of the IAM instance profile to attach"
  type        = string
  default     = null
}

variable "user_data" {
  description = "User data script to run when the instance launches (e.g. install Docker and run ECR container)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
