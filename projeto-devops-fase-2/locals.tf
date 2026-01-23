# Common tags and values used across all resources
locals {
  common_tags = {
    Environment = var.environment
    Project     = "laboratorio-devops"
    ManagedBy   = "Terraform"
    Cliente     = var.client_name
    CreatedAt   = timestamp()
  }

  # Resource naming prefix
  name_prefix = "${var.environment}-${var.project_name}"
}
