#ECR Repository
resource "aws_ecr_repository" "ecr_site" {
  name                 = var.ecr_repository_name
  image_tag_mutability = "MUTABLE"
}