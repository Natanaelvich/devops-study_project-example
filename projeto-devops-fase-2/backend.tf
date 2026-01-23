# Backend configuration for Terraform state
# 
# IMPORTANT: Backend configuration cannot use variables.
# You have two options:
#
# Option 1: Configure directly here (current approach)
# Option 2: Use a separate backend config file (recommended for sensitive data)
#   - Copy backend.hcl.example to backend.hcl
#   - Fill in your values
#   - Run: terraform init -backend-config=backend.hcl
#
terraform {
  backend "s3" {
    bucket  = "terraform-state-natanaelvich"
    key     = "site/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
