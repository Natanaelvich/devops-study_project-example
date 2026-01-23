# Main Terraform configuration using modules
# This follows the recommended architecture pattern from the best practices guide

# IAM Module - Creates IAM role and instance profile for EC2 to access ECR
module "iam" {
  source = "./modules/iam"

  role_name = var.iam_role_name != "" ? var.iam_role_name : "${local.name_prefix}-ecr-role"

  tags = local.common_tags
}

# Security Group Module - Creates security group with ingress/egress rules
module "security_group" {
  source = "./modules/security-group"

  name        = var.security_group_name != "" ? var.security_group_name : "${local.name_prefix}-sg"
  description = "Security group for ${local.name_prefix} website server"
  vpc_id      = var.vpc_id

  ssh_allowed_cidr   = var.ssh_allowed_ip
  http_allowed_cidr  = "0.0.0.0/0"
  https_allowed_cidr = "0.0.0.0/0"

  tags = local.common_tags
}

# EC2 Module - Creates EC2 instance
module "ec2" {
  source = "./modules/ec2"

  name                      = var.instance_name != "" ? var.instance_name : "${local.name_prefix}-server"
  ami_id                    = data.aws_ami.amazon_linux_2.id
  instance_type             = var.instance_type
  key_pair_name             = var.key_pair_name
  security_group_ids        = [module.security_group.security_group_id]
  iam_instance_profile_name = module.iam.instance_profile_name

  tags = local.common_tags
}

# ECR Module - Creates ECR repository
module "ecr" {
  source = "./modules/ecr"

  repository_name      = var.ecr_repository_name
  image_tag_mutability = "MUTABLE"
  scan_on_push         = false
  encryption_type      = "AES256"

  tags = local.common_tags
}
