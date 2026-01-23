# Data source para buscar a AMI mais recente do Amazon Linux 2
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# IAM Role para permitir que a EC2 acesse o ECR
resource "aws_iam_role" "ecr_ec2_role" {
  name = "ECR-EC2-Role"

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

  tags = {
    Name        = "ECR-EC2-Role"
    Provisioned = "Terraform"
    Cliente     = "Natanael"
  }
}

# Anexar política gerenciada da AWS para acesso ao ECR (somente leitura)
resource "aws_iam_role_policy_attachment" "ecr_readonly" {
  role       = aws_iam_role.ecr_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Instance Profile - container que permite anexar a role à EC2
resource "aws_iam_instance_profile" "ecr_ec2_profile" {
  name = "ECR-EC2-Role"
  role = aws_iam_role.ecr_ec2_role.name

  tags = {
    Name        = "ECR-EC2-Role"
    Provisioned = "Terraform"
    Cliente     = "Natanael"
  }
}

resource "aws_instance" "website_server" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t2.micro"
  key_name               = "chave-site-prod"
  vpc_security_group_ids = [aws_security_group.website_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ecr_ec2_profile.name

  tags = {
    Name        = "website-server"
    Provisioned = "Terraform"
    Cliente     = "Natanael"
  }
}

## Security Group
resource "aws_security_group" "website_sg" {
  name   = "website-sg"
  vpc_id = "vpc-b2083cc8"
  tags = {
    Name        = "website-sg"
    Provisioned = "Terraform"
    Cliente     = "Natanael"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.website_sg.id
  cidr_ipv4         = "200.106.133.23/32"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.website_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_https" {
  security_group_id = aws_security_group.website_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "allow_all_outbound" {
  security_group_id = aws_security_group.website_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = -1
}

