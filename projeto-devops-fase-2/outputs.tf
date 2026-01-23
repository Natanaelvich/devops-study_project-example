# Outputs from IAM module
output "iam_role_name" {
  description = "Name of the IAM role"
  value       = module.iam.role_name
}

output "iam_role_arn" {
  description = "ARN of the IAM role"
  value       = module.iam.role_arn
}

output "iam_instance_profile_name" {
  description = "Name of the IAM instance profile"
  value       = module.iam.instance_profile_name
}

# Outputs from Security Group module
output "security_group_id" {
  description = "ID of the security group"
  value       = module.security_group.security_group_id
}

output "security_group_arn" {
  description = "ARN of the security group"
  value       = module.security_group.security_group_arn
}

# Outputs from EC2 module
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = module.ec2.instance_id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = module.ec2.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = module.ec2.private_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = module.ec2.public_dns
}

# Outputs from ECR module
output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = module.ecr.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  value       = module.ecr.repository_arn
}
