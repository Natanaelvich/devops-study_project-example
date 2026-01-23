# 🧩 Terraform Modules - Módulos Reutilizáveis

Este documento explica como criar e usar módulos Terraform para reutilização de código.

---

## 📑 Table of Contents

1. [O que são Módulos?](#-o-que-são-módulos)
2. [Estrutura de um Módulo](#-estrutura-de-um-módulo)
3. [Criando um Módulo](#-criando-um-módulo)
4. [Usando Módulos](#-usando-módulos)
5. [Módulos Locais vs Remotos](#-módulos-locais-vs-remotos)
6. [Módulos da Comunidade](#-módulos-da-comunidade)
7. [Best Practices](#-best-practices)

---

## 📦 O que são Módulos?

**Módulos** são containers para múltiplos recursos que são usados juntos. Eles permitem:

- **Reutilização** de código
- **Organização** de infraestrutura
- **Abstração** de complexidade
- **Versionamento** de componentes

### Tipos de Módulos

1. **Módulos Locais**: No mesmo repositório
2. **Módulos Remotos**: Git, S3, Terraform Registry
3. **Módulos da Comunidade**: Terraform Registry

---

## 📁 Estrutura de um Módulo

### Estrutura Mínima

```
modules/ec2-instance/
├── main.tf          # Recursos principais
├── variables.tf     # Variáveis de entrada
└── outputs.tf       # Outputs do módulo
```

### Estrutura Completa

```
modules/ec2-instance/
├── main.tf          # Recursos principais
├── variables.tf     # Variáveis de entrada
├── outputs.tf       # Outputs do módulo
├── versions.tf      # Versões de providers
├── README.md        # Documentação
└── examples/        # Exemplos de uso
    └── basic/
        └── main.tf
```

---

## 🛠️ Criando um Módulo

### Exemplo: Módulo EC2 Instance

```hcl
# modules/ec2-instance/main.tf
resource "aws_instance" "this" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  
  vpc_security_group_ids = var.security_group_ids
  
  key_name = var.key_name
  
  user_data = var.user_data
  
  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )
}

# modules/ec2-instance/variables.tf
variable "ami_id" {
  description = "AMI ID para a instância"
  type        = string
}

variable "instance_type" {
  description = "Tipo de instância EC2"
  type        = string
  default     = "t2.micro"
}

variable "subnet_id" {
  description = "ID da subnet onde a instância será criada"
  type        = string
}

variable "security_group_ids" {
  description = "Lista de IDs dos security groups"
  type        = list(string)
  default     = []
}

variable "key_name" {
  description = "Nome da key pair para acesso SSH"
  type        = string
  default     = null
}

variable "user_data" {
  description = "Script user-data para inicialização"
  type        = string
  default     = null
}

variable "name" {
  description = "Nome da instância (usado em tags)"
  type        = string
}

variable "tags" {
  description = "Tags adicionais para a instância"
  type        = map(string)
  default     = {}
}

# modules/ec2-instance/outputs.tf
output "instance_id" {
  description = "ID da instância EC2"
  value       = aws_instance.this.id
}

output "private_ip" {
  description = "IP privado da instância"
  value       = aws_instance.this.private_ip
}

output "public_ip" {
  description = "IP público da instância"
  value       = aws_instance.this.public_ip
}

output "arn" {
  description = "ARN da instância"
  value       = aws_instance.this.arn
}
```

### Exemplo: Módulo Security Group

```hcl
# modules/security-group/main.tf
resource "aws_security_group" "this" {
  name        = var.name
  description = var.description
  vpc_id      = var.vpc_id
  
  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = var.ingress_rules
  
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = each.value.cidr_ipv4
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  ip_protocol       = each.value.protocol
}

resource "aws_vpc_security_group_egress_rule" "this" {
  for_each = var.egress_rules
  
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = each.value.cidr_ipv4
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  ip_protocol       = each.value.protocol
}

# modules/security-group/variables.tf
variable "name" {
  description = "Nome do security group"
  type        = string
}

variable "description" {
  description = "Descrição do security group"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "ID da VPC"
  type        = string
}

variable "ingress_rules" {
  description = "Regras de entrada"
  type = map(object({
    cidr_ipv4 = string
    from_port = number
    to_port   = number
    protocol  = string
  }))
  default = {}
}

variable "egress_rules" {
  description = "Regras de saída"
  type = map(object({
    cidr_ipv4 = string
    from_port = number
    to_port   = number
    protocol  = string
  }))
  default = {}
}

variable "tags" {
  description = "Tags adicionais"
  type        = map(string)
  default     = {}
}

# modules/security-group/outputs.tf
output "security_group_id" {
  description = "ID do security group"
  value       = aws_security_group.this.id
}

output "arn" {
  description = "ARN do security group"
  value       = aws_security_group.this.arn
}
```

---

## 📥 Usando Módulos

### Módulo Local

```hcl
# main.tf
module "web_server" {
  source = "./modules/ec2-instance"
  
  ami_id        = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public[0].id
  name          = "web-server"
  
  security_group_ids = [
    module.web_sg.security_group_id
  ]
  
  key_name = "chave-site-prod"
  
  tags = {
    Environment = "production"
    Project     = "laboratorio-devops"
  }
}

module "web_sg" {
  source = "./modules/security-group"
  
  name        = "web-sg"
  description = "Security group para web servers"
  vpc_id      = aws_vpc.main.id
  
  ingress_rules = {
    ssh = {
      cidr_ipv4 = "200.106.133.23/32"
      from_port = 22
      to_port   = 22
      protocol  = "tcp"
    }
    http = {
      cidr_ipv4 = "0.0.0.0/0"
      from_port = 80
      to_port   = 80
      protocol  = "tcp"
    }
    https = {
      cidr_ipv4 = "0.0.0.0/0"
      from_port = 443
      to_port   = 443
      protocol  = "tcp"
    }
  }
  
  egress_rules = {
    all = {
      cidr_ipv4 = "0.0.0.0/0"
      from_port = 0
      to_port   = 65535
      protocol  = "-1"
    }
  }
}

# Usar outputs do módulo
output "web_server_ip" {
  value = module.web_server.public_ip
}
```

### Módulo com Múltiplas Instâncias

```hcl
# Criar múltiplas instâncias
module "web_servers" {
  source = "./modules/ec2-instance"
  
  for_each = {
    web1 = { subnet = aws_subnet.public[0].id }
    web2 = { subnet = aws_subnet.public[1].id }
  }
  
  ami_id        = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  subnet_id     = each.value.subnet
  name          = "web-server-${each.key}"
  
  security_group_ids = [module.web_sg.security_group_id]
  key_name           = "chave-site-prod"
}
```

---

## 🌐 Módulos Locais vs Remotos

### Módulo Local

```hcl
module "local_module" {
  source = "./modules/ec2-instance"
  # ...
}
```

**Vantagens:**
- Fácil de modificar
- Controle total
- Desenvolvimento rápido

**Desvantagens:**
- Não reutilizável entre projetos
- Sem versionamento

### Módulo do Git

```hcl
module "git_module" {
  source = "git::https://github.com/org/module-ec2.git?ref=v1.0.0"
  # ...
}
```

**Vantagens:**
- Versionamento
- Reutilizável
- Colaboração

### Módulo do Terraform Registry

```hcl
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"
  
  name = "my-vpc"
  cidr = "10.0.0.0/16"
  
  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.10.0/24", "10.0.20.0/24"]
  
  enable_nat_gateway = true
  enable_vpn_gateway = false
}
```

**Vantagens:**
- Testado pela comunidade
- Documentado
- Mantido ativamente

---

## 🏪 Módulos da Comunidade

### Módulos Populares

1. **VPC Module**
   ```hcl
   module "vpc" {
     source  = "terraform-aws-modules/vpc/aws"
     version = "~> 5.0"
   }
   ```

2. **EC2 Instance Module**
   ```hcl
   module "ec2" {
     source  = "terraform-aws-modules/ec2-instance/aws"
     version = "~> 5.0"
   }
   ```

3. **Security Group Module**
   ```hcl
   module "security_group" {
     source  = "terraform-aws-modules/security-group/aws"
     version = "~> 5.0"
   }
   ```

### Buscar Módulos

- [Terraform Registry](https://registry.terraform.io/)
- Filtrar por provider (AWS, Azure, GCP)
- Ver documentação e exemplos

---

## ✅ Best Practices

### 1. Documente Módulos

```markdown
# modules/ec2-instance/README.md

# EC2 Instance Module

Cria uma instância EC2 com configurações customizáveis.

## Usage

```hcl
module "server" {
  source = "./modules/ec2-instance"
  
  ami_id        = "ami-123456"
  instance_type = "t2.micro"
  subnet_id     = "subnet-123456"
  name          = "web-server"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| ami_id | AMI ID | string | - | yes |
| instance_type | Instance type | string | "t2.micro" | no |

## Outputs

| Name | Description |
|------|-------------|
| instance_id | EC2 Instance ID |
| public_ip | Public IP address |
```

### 2. Use Versions

```hcl
# modules/ec2-instance/versions.tf
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

### 3. Valide Variáveis

```hcl
variable "instance_type" {
  description = "Tipo de instância"
  type        = string
  
  validation {
    condition = contains([
      "t2.micro", "t2.small", "t2.medium",
      "t3.micro", "t3.small", "t3.medium"
    ], var.instance_type)
    error_message = "Instance type must be a valid t2 or t3 type."
  }
}
```

### 4. Use Locals para Lógica Complexa

```hcl
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "Terraform"
  }
  
  instance_tags = merge(
    local.common_tags,
    var.additional_tags,
    {
      Name = var.name
    }
  )
}
```

### 5. Forneça Exemplos

```
modules/ec2-instance/
├── examples/
│   ├── basic/
│   │   └── main.tf
│   └── with-user-data/
│       └── main.tf
```

---

## 📋 Checklist de Módulos

- [ ] Estrutura de diretórios organizada
- [ ] Variáveis documentadas
- [ ] Outputs documentados
- [ ] README.md criado
- [ ] Exemplos fornecidos
- [ ] Versões de providers especificadas
- [ ] Validação de variáveis
- [ ] Tags padronizadas
- [ ] Testes (opcional)

---

## 🔗 Referências

- [Terraform Best Practices](./003-terraform-best-practices.md)
- [Terraform Best Architectures](./004-terraform-best-architectures.md)
- [Terraform Registry](https://registry.terraform.io/)
- [Documentação Oficial - Modules](https://www.terraform.io/docs/language/modules/index.html)

---

**Última atualização:** 2026-01-23
