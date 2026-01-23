# Módulo EC2

Este módulo cria instâncias EC2 com configurações personalizáveis.

## Recursos Criados

- `aws_instance` - Instância EC2

## Uso

```hcl
module "ec2" {
  source = "./modules/ec2"

  name           = "web-server"
  ami_id         = "ami-12345678"
  instance_type  = "t2.micro"
  key_pair_name  = "my-key-pair"
  security_group_ids = [aws_security_group.web.id]

  tags = {
    Environment = "dev"
  }
}
```

## Variáveis

| Nome | Descrição | Tipo | Padrão | Obrigatório |
|------|-----------|------|--------|-------------|
| `name` | Nome da instância (usado na tag Name) | `string` | - | Sim |
| `ami_id` | ID da AMI para a instância | `string` | - | Sim |
| `instance_type` | Tipo de instância EC2 | `string` | `"t2.micro"` | Não |
| `key_pair_name` | Nome da AWS Key Pair para acesso SSH | `string` | - | Sim |
| `security_group_ids` | Lista de IDs de security groups | `list(string)` | - | Sim |
| `iam_instance_profile_name` | Nome do IAM instance profile (opcional) | `string` | `null` | Não |
| `tags` | Tags para aplicar aos recursos | `map(string)` | `{}` | Não |

## Outputs

| Nome | Descrição |
|------|-----------|
| `instance_id` | ID da instância EC2 |
| `instance_arn` | ARN da instância EC2 |
| `private_ip` | IP privado da instância |
| `public_ip` | IP público da instância |
| `public_dns` | DNS público da instância |

## Exemplo de Uso Completo

```hcl
# Data source para buscar AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Security group
module "sg" {
  source = "./modules/security-group"
  # ...
}

# IAM role
module "iam" {
  source = "./modules/iam"
  # ...
}

# Instância EC2
module "ec2" {
  source = "./modules/ec2"

  name           = "web-server-01"
  ami_id         = data.aws_ami.amazon_linux.id
  instance_type  = "t3.small"
  key_pair_name  = var.key_pair_name
  security_group_ids = [module.sg.security_group_id]
  iam_instance_profile_name = module.iam.instance_profile_name

  tags = {
    Environment = "production"
    Role        = "web-server"
  }
}

# Outputs
output "server_ip" {
  value = module.ec2.public_ip
}
```
