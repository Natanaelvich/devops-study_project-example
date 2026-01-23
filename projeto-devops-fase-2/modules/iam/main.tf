# IAM Role para permitir que a EC2 acesse o ECR
resource "aws_iam_role" "ecr_ec2_role" {
  name = var.role_name

  # Trust Policy: permite que o serviço EC2 assuma esta role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = var.role_name
    }
  )
}

# Anexar política gerenciada da AWS para acesso ao ECR (somente leitura)
resource "aws_iam_role_policy_attachment" "ecr_readonly" {
  role       = aws_iam_role.ecr_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Instance Profile - container que permite anexar a role à EC2
resource "aws_iam_instance_profile" "ecr_ec2_profile" {
  name = var.role_name
  role = aws_iam_role.ecr_ec2_role.name

  tags = merge(
    var.tags,
    {
      Name = var.role_name
    }
  )
}
