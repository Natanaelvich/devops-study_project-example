# state.tf
terraform {
  backend "s3" {
    bucket  = "terraform-state-natanaelvich"
    key     = "site/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
