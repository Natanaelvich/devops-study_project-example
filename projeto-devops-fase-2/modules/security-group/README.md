# Módulo Security Group

Este módulo cria um security group com regras de ingress e egress configuráveis.

## Recursos Criados

- `aws_security_group` - Security group principal
- `aws_vpc_security_group_ingress_rule` - Regras de entrada (SSH, HTTP, HTTPS)
- `aws_vpc_security_group_egress_rule` - Regra de saída (all traffic)

## Uso

```hcl
module "security_group" {
  source = "./modules/security-group"

  name        = "web-sg"
  description = "Security group for web servers"
  vpc_id      = "vpc-12345678"

  ssh_allowed_cidr  = "10.0.0.0/8"
  http_allowed_cidr = "0.0.0.0/0"
  https_allowed_cidr = "0.0.0.0/0"

  tags = {
    Environment = "dev"
  }
}
```

## Variáveis

| Nome | Descrição | Tipo | Padrão | Obrigatório |
|------|-----------|------|--------|-------------|
| `name` | Nome do security group | `string` | - | Sim |
| `description` | Descrição do security group | `string` | `"Security group managed by Terraform"` | Não |
| `vpc_id` | ID da VPC onde o security group será criado | `string` | - | Sim |
| `ssh_allowed_cidr` | CIDR permitido para SSH (porta 22) | `string` | `"0.0.0.0/0"` | Não |
| `http_allowed_cidr` | CIDR permitido para HTTP (porta 80) | `string` | `"0.0.0.0/0"` | Não |
| `https_allowed_cidr` | CIDR permitido para HTTPS (porta 443) | `string` | `"0.0.0.0/0"` | Não |
| `tags` | Tags para aplicar aos recursos | `map(string)` | `{}` | Não |

## Outputs

| Nome | Descrição |
|------|-----------|
| `security_group_id` | ID do security group |
| `security_group_arn` | ARN do security group |
| `security_group_name` | Nome do security group |

## Exemplo de Uso Completo

```hcl
module "security_group" {
  source = "./modules/security-group"

  name        = "web-server-sg"
  description = "Security group for web application"
  vpc_id      = var.vpc_id

  # Restringir SSH apenas ao seu IP
  ssh_allowed_cidr = "203.0.113.0/32"
  
  # Permitir HTTP/HTTPS de qualquer lugar
  http_allowed_cidr  = "0.0.0.0/0"
  https_allowed_cidr = "0.0.0.0/0"

  tags = {
    Environment = "production"
    Project     = "web-app"
  }
}

# Usar o security group em uma instância EC2
resource "aws_instance" "web" {
  # ...
  vpc_security_group_ids = [module.security_group.security_group_id]
}
```
