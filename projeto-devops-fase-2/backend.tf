# Backend configuration for Terraform state
# 
# IMPORTANT: Backend configuration cannot use variables.
# You have two options:
#
# Option 1: Configure directly here (uncomment and fill values)
# Option 2: Use a separate backend config file (recommended)
#   - Copy backend.hcl.example to backend.hcl
#   - Fill in your values
#   - Run: terraform init -backend-config=backend.hcl
#
terraform {
  backend "s3" {
    # Uncomment and configure these values:
    # bucket  = "your-terraform-state-bucket"
    # key     = "site/terraform.tfstate"
    # region  = "us-east-1"
    # encrypt = true
  }
}
