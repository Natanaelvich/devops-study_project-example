# ✨ Terraform Best Practices - Melhores Práticas

Este documento apresenta as melhores práticas para trabalhar com Terraform, baseadas em experiências da comunidade e documentação oficial.

---

## 📑 Table of Contents

1. [Estrutura de Arquivos](#-estrutura-de-arquivos)
2. [Nomenclatura](#-nomenclatura)
3. [Organização de Código](#-organização-de-código)
4. [Gerenciamento de Estado](#-gerenciamento-de-estado)
5. [Variáveis e Outputs](#-variáveis-e-outputs)
6. [Segurança](#-segurança)
7. [Versionamento](#-versionamento)
8. [Performance](#-performance)
9. [Documentação](#-documentação)
10. [CI/CD](#-cicd)

---

## 📁 Estrutura de Arquivos

### Estrutura Recomendada

```
projeto-devops-fase-2/
├── .docs/                    # Documentação
├── modules/                  # Módulos reutilizáveis
│   ├── ec2/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── security-group/
├── environments/             # Ambientes separados
│   ├── dev/
│   │   ├── main.tf
│   │   └── terraform.tfvars
│   └── prod/
│       ├── main.tf
│       └── terraform.tfvars
├── backend.tf               # Configuração do backend
├── provider.tf               # Configuração do provider
├── variables.tf              # Variáveis globais
├── outputs.tf                 # Outputs globais
├── terraform.tfvars          # Valores de variáveis (não commitar)
├── terraform.tfvars.example  # Exemplo de variáveis
└── .gitignore                # Ignorar arquivos sensíveis
```

### Separação de Responsabilidades

```hcl
# provider.tf - Apenas configuração de providers
provider "aws" {
  region = var.aws_region
}

# backend.tf - Apenas configuração de backend
terraform {
  backend "s3" {
    bucket = "terraform-state-natanaelvich"
    key    = "site/terraform.tfstate"
    region = "us-east-1"
  }
}

# variables.tf - Apenas declaração de variáveis
variable "instance_type" {
  description = "Tipo de instância EC2"
  type        = string
  default     = "t2.micro"
}

# outputs.tf - Apenas outputs
output "instance_ip" {
  description = "IP público da instância"
  value       = aws_instance.website_server.public_ip
}
```

---

## 🏷️ Nomenclatura

### Recursos
```hcl
# ✅ BOM: Nome descritivo e consistente
resource "aws_instance" "website_server" {
  # ...
}

resource "aws_security_group" "website_sg" {
  # ...
}

# ❌ RUIM: Nomes genéricos
resource "aws_instance" "server1" {
  # ...
}
```

### Variáveis
```hcl
# ✅ BOM: snake_case, descritivo
variable "instance_type" {
  description = "Tipo de instância EC2"
  type        = string
}

# ❌ RUIM: camelCase ou abreviações
variable "instType" {
  # ...
}
```

### Tags
```hcl
# ✅ BOM: Tags consistentes e padronizadas
tags = {
  Name        = "website-server"
  Environment = "production"
  Project     = "laboratorio-devops"
  ManagedBy   = "Terraform"
  Cliente     = "Natanael"
}

# ❌ RUIM: Tags inconsistentes
tags = {
  name = "server"
  env  = "prod"
}
```

---

## 📦 Organização de Código

### Use Módulos para Reutilização

```hcl
# modules/ec2-instance/main.tf
resource "aws_instance" "this" {
  ami           = var.ami_id
  instance_type = var.instance_type
  # ...
}

# main.tf
module "web_server" {
  source = "./modules/ec2-instance"
  
  ami_id        = "ami-0b016c703b95ecbe4"
  instance_type = "t2.micro"
}
```

### Evite Hardcoding

```hcl
# ❌ RUIM: Valores hardcoded
resource "aws_instance" "server" {
  ami           = "ami-0b016c703b95ecbe4"
  instance_type = "t2.micro"
  vpc_id        = "vpc-0ff60a695425883cf"
}

# ✅ BOM: Usar variáveis e data sources
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "server" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  vpc_id        = var.vpc_id
}
```

### Use Data Sources

```hcl
# Buscar VPC existente
data "aws_vpc" "main" {
  id = var.vpc_id
}

# Buscar AMI mais recente
data "aws_ami" "latest" {
  most_recent = true
  owners      = ["amazon"]
}

# Buscar availability zones
data "aws_availability_zones" "available" {
  state = "available"
}
```

---

## 💾 Gerenciamento de Estado

### Backend Remoto

```hcl
# ✅ SEMPRE use backend remoto (S3)
terraform {
  backend "s3" {
    bucket         = "terraform-state-natanaelvich"
    key            = "site/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"  # Opcional mas recomendado
  }
}
```

### State Locking

```hcl
# Use DynamoDB para state locking
terraform {
  backend "s3" {
    # ...
    dynamodb_table = "terraform-state-lock"
  }
}
```

### Não Commitar State

```gitignore
# .gitignore
*.tfstate
*.tfstate.*
.terraform/
.terraform.lock.hcl
*.tfvars
!*.tfvars.example
crash.log
override.tf
override.tf.json
*_override.tf
*_override.tf.json
```

---

## 🔧 Variáveis e Outputs

### Variáveis Bem Definidas

```hcl
# ✅ BOM: Variável completa
variable "instance_type" {
  description = "Tipo de instância EC2"
  type        = string
  default     = "t2.micro"
  
  validation {
    condition = contains(["t2.micro", "t2.small", "t2.medium"], var.instance_type)
    error_message = "Instance type must be t2.micro, t2.small, or t2.medium."
  }
}

# ❌ RUIM: Variável sem descrição ou validação
variable "instance_type" {
  default = "t2.micro"
}
```

### Outputs Úteis

```hcl
# ✅ BOM: Output descritivo
output "website_url" {
  description = "URL do website"
  value       = "http://${aws_instance.website_server.public_ip}"
  sensitive   = false
}

output "database_password" {
  description = "Senha do banco de dados"
  value       = random_password.db_password.result
  sensitive   = true  # Marcar como sensível
}
```

---

## 🔒 Segurança

### Não Commitar Credenciais

```gitignore
# .gitignore
*.tfvars
!*.tfvars.example
secrets.tfvars
*.pem
*.key
```

### Use Secrets Manager

```hcl
# Buscar secret do AWS Secrets Manager
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "database/password"
}

resource "aws_db_instance" "main" {
  password = jsondecode(data.aws_secretsmanager_secret_version.db_password.secret_string)["password"]
}
```

### Use IAM Roles

```hcl
# ✅ BOM: Usar IAM roles ao invés de access keys
provider "aws" {
  region = "us-east-1"
  # Não especificar access_key e secret_key
  # Usar profile ou IAM role
}
```

### Validação de Inputs

```hcl
variable "cidr_block" {
  description = "CIDR block para VPC"
  type        = string
  
  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "CIDR block must be a valid IPv4 CIDR."
  }
}
```

---

## 📌 Versionamento

### Pin Versions

```hcl
# ✅ BOM: Especificar versão do provider
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"  # Permite 5.x mas não 6.0
    }
  }
}
```

### Use .terraform.lock.hcl

```bash
# Commitar arquivo de lock
git add .terraform.lock.hcl
git commit -m "Lock provider versions"
```

---

## ⚡ Performance

### Use `-parallelism`

```bash
# Limitar paralelismo para evitar rate limits
terraform apply -parallelism=10
```

### Use `count` e `for_each` com Cuidado

```hcl
# ✅ BOM: for_each para recursos únicos
resource "aws_instance" "servers" {
  for_each = var.server_configs
  
  ami           = each.value.ami
  instance_type = each.value.instance_type
}

# ✅ BOM: count para recursos similares
resource "aws_instance" "servers" {
  count = 3
  
  ami           = var.ami_id
  instance_type = var.instance_type
}
```

### Evite Dependências Desnecessárias

```hcl
# ❌ RUIM: Dependência implícita desnecessária
resource "aws_instance" "server" {
  # ...
  user_data = "echo ${aws_s3_bucket.data.bucket}"
}

# ✅ BOM: Usar depends_on explicitamente
resource "aws_instance" "server" {
  # ...
  depends_on = [aws_s3_bucket.data]
}
```

---

## 📚 Documentação

### Comentários Úteis

```hcl
# Este security group permite acesso SSH apenas do IP específico
# e tráfego HTTP/HTTPS de qualquer lugar
resource "aws_security_group" "website_sg" {
  # ...
}

# TODO: Adicionar WAF para proteção adicional
# FIXME: Substituir AMI hardcoded por data source
```

### README.md

```markdown
# Projeto DevOps Fase 2

## Descrição
Infraestrutura para website usando Terraform.

## Pré-requisitos
- Terraform >= 1.0
- AWS CLI configurado
- Profile: terraform-study

## Uso
```bash
terraform init
terraform plan
terraform apply
```

## Variáveis
Ver `terraform.tfvars.example`
```

---

## 🔄 CI/CD

### Pipeline Básico

```yaml
# .github/workflows/terraform.yaml
name: Terraform

on:
  push:
    branches: [main]

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
      
      - name: Terraform Init
        run: terraform init
      
      - name: Terraform Validate
        run: terraform validate
      
      - name: Terraform Format Check
        run: terraform fmt -check
      
      - name: Terraform Plan
        run: terraform plan -out=tfplan
      
      - name: Terraform Apply
        if: github.ref == 'refs/heads/main'
        run: terraform apply -auto-approve tfplan
```

---

## ✅ Checklist de Boas Práticas

- [ ] Estrutura de arquivos organizada
- [ ] Nomenclatura consistente
- [ ] Backend remoto configurado
- [ ] State locking habilitado
- [ ] Variáveis com descrição e validação
- [ ] Outputs documentados
- [ ] Sem credenciais hardcoded
- [ ] Versões de providers especificadas
- [ ] .gitignore configurado
- [ ] Documentação atualizada
- [ ] Código formatado (`terraform fmt`)
- [ ] Validação passando (`terraform validate`)

---

## 🔗 Referências

- [Terraform Commands](./002-terraform-commands.md)
- [Terraform State Management](./006-terraform-state-management.md)
- [Terraform Modules](./007-terraform-modules.md)
- [Documentação Oficial Terraform](https://www.terraform.io/docs)

---

**Última atualização:** 2026-01-23
