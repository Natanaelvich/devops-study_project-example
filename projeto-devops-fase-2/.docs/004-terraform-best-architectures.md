# 🏗️ Terraform Best Architectures - Arquiteturas Recomendadas

Este documento apresenta padrões arquiteturais recomendados para infraestrutura com Terraform.

---

## 📑 Table of Contents

1. [Arquitetura de Projeto](#-arquitetura-de-projeto)
2. [Estrutura Modular](#-estrutura-modular)
3. [Multi-Environment](#-multi-environment)
4. [State Management](#-state-management)
5. [Workspaces vs Diretórios](#-workspaces-vs-diretórios)
6. [Padrões de Nomenclatura](#-padrões-de-nomenclatura)
7. [Arquitetura de Rede](#-arquitetura-de-rede)
8. [Arquitetura de Aplicação](#-arquitetura-de-aplicação)

---

## 📁 Arquitetura de Projeto

### Estrutura Recomendada para Projetos Pequenos/Médios

```
projeto/
├── .docs/                    # Documentação
├── modules/                  # Módulos reutilizáveis
│   ├── ec2/
│   ├── security-group/
│   └── vpc/
├── environments/             # Ambientes
│   ├── dev/
│   ├── staging/
│   └── prod/
├── shared/                   # Recursos compartilhados
│   ├── backend.tf
│   └── provider.tf
└── scripts/                  # Scripts auxiliares
```

### Estrutura para Projetos Grandes

```
projeto/
├── infrastructure/
│   ├── networking/           # VPC, Subnets, etc
│   ├── compute/              # EC2, ECS, etc
│   ├── storage/              # S3, EBS, etc
│   ├── security/             # IAM, Security Groups
│   └── monitoring/           # CloudWatch, etc
├── modules/                  # Módulos compartilhados
├── environments/
│   ├── dev/
│   ├── staging/
│   └── prod/
└── shared/                   # Backend, Provider
```

---

## 🧩 Estrutura Modular

### Módulo Básico

```
modules/ec2-instance/
├── main.tf                   # Recursos principais
├── variables.tf              # Variáveis de entrada
├── outputs.tf                # Outputs do módulo
├── README.md                 # Documentação
└── versions.tf               # Versões de providers
```

**Exemplo de Módulo:**

```hcl
# modules/ec2-instance/main.tf
resource "aws_instance" "this" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  
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
  description = "Tipo de instância"
  type        = string
  default     = "t2.micro"
}

variable "subnet_id" {
  description = "ID da subnet"
  type        = string
}

variable "name" {
  description = "Nome da instância"
  type        = string
}

variable "tags" {
  description = "Tags adicionais"
  type        = map(string)
  default     = {}
}

# modules/ec2-instance/outputs.tf
output "instance_id" {
  description = "ID da instância"
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
```

**Uso do Módulo:**

```hcl
# main.tf
module "web_server" {
  source = "./modules/ec2-instance"
  
  ami_id        = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public[0].id
  name          = "web-server"
  
  tags = {
    Environment = "production"
    Project     = "laboratorio-devops"
  }
}
```

---

## 🌍 Multi-Environment

### Abordagem 1: Diretórios Separados (Recomendado)

```
environments/
├── dev/
│   ├── main.tf
│   ├── variables.tf
│   ├── terraform.tfvars
│   └── backend.tf
├── staging/
│   ├── main.tf
│   ├── variables.tf
│   ├── terraform.tfvars
│   └── backend.tf
└── prod/
    ├── main.tf
    ├── variables.tf
    ├── terraform.tfvars
    └── backend.tf
```

**Vantagens:**
- Isolamento completo entre ambientes
- Estados separados
- Fácil de gerenciar
- Menos risco de aplicar mudanças no ambiente errado

**Exemplo:**

```hcl
# environments/dev/main.tf
module "infrastructure" {
  source = "../../modules"
  
  environment = "dev"
  instance_type = "t2.micro"
  # ...
}

# environments/dev/terraform.tfvars
environment   = "dev"
instance_type = "t2.micro"
instance_count = 1

# environments/prod/terraform.tfvars
environment   = "prod"
instance_type = "t2.large"
instance_count = 3
```

### Abordagem 2: Workspaces

```
projeto/
├── main.tf
├── variables.tf
└── terraform.tfvars
```

```bash
# Criar workspaces
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# Selecionar workspace
terraform workspace select prod

# Aplicar
terraform apply -var-file="prod.tfvars"
```

**Vantagens:**
- Código único
- Menos duplicação
- Fácil de manter

**Desvantagens:**
- Risco de aplicar no ambiente errado
- Estado compartilhado (mas separado por workspace)

---

## 💾 State Management

### Estrutura de Backend por Ambiente

```hcl
# environments/dev/backend.tf
terraform {
  backend "s3" {
    bucket = "terraform-state-natanaelvich"
    key    = "dev/terraform.tfstate"
    region = "us-east-1"
  }
}

# environments/prod/backend.tf
terraform {
  backend "s3" {
    bucket = "terraform-state-natanaelvich"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
  }
}
```

### State Locking com DynamoDB

```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state-natanaelvich"
    key            = "site/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

---

## 🏷️ Padrões de Nomenclatura

### Recursos

```hcl
# Padrão: {resource_type}.{environment}_{purpose}_{identifier}

# Exemplos:
resource "aws_instance" "prod_web_01" {
  # ...
}

resource "aws_security_group" "dev_web_sg" {
  # ...
}

resource "aws_s3_bucket" "prod_logs_bucket" {
  # ...
}
```

### Tags Padronizadas

```hcl
locals {
  common_tags = {
    Environment = var.environment
    Project     = "laboratorio-devops"
    ManagedBy   = "Terraform"
    Cliente     = "Natanael"
    CreatedAt   = timestamp()
  }
}

resource "aws_instance" "server" {
  # ...
  tags = merge(local.common_tags, {
    Name = "web-server-${var.environment}"
  })
}
```

---

## 🌐 Arquitetura de Rede

### VPC com Subnets Públicas e Privadas

```hcl
# networking/main.tf
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  
  name = "main-vpc"
  cidr = "10.0.0.0/16"
  
  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.10.0/24", "10.0.20.0/24"]
  
  enable_nat_gateway = true
  enable_vpn_gateway = false
  
  tags = {
    Environment = var.environment
  }
}
```

### Security Groups em Camadas

```hcl
# Security Group para Load Balancer
resource "aws_security_group" "alb" {
  name = "${var.environment}-alb-sg"
  # Permite HTTP/HTTPS de qualquer lugar
}

# Security Group para Web Servers
resource "aws_security_group" "web" {
  name = "${var.environment}-web-sg"
  # Permite tráfego apenas do ALB
  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
}

# Security Group para Database
resource "aws_security_group" "db" {
  name = "${var.environment}-db-sg"
  # Permite tráfego apenas dos Web Servers
  ingress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"
    security_groups = [aws_security_group.web.id]
  }
}
```

---

## 🚀 Arquitetura de Aplicação

### Arquitetura de 3 Camadas

```
┌─────────────────┐
│   Load Balancer │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
┌───▼───┐ ┌───▼───┐
│ Web 1 │ │ Web 2 │
└───┬───┘ └───┬───┘
    │         │
    └────┬────┘
         │
    ┌────▼────┐
    │  RDS DB │
    └─────────┘
```

**Terraform:**

```hcl
# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = module.vpc.public_subnets
  security_groups    = [aws_security_group.alb.id]
}

# Target Group
resource "aws_lb_target_group" "web" {
  name     = "${var.environment}-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
}

# Web Servers
module "web_servers" {
  source = "./modules/ec2-instance"
  count  = 2
  
  ami_id        = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  subnet_id     = module.vpc.private_subnets[count.index]
  security_groups = [aws_security_group.web.id]
}

# RDS Database
resource "aws_db_instance" "main" {
  identifier     = "${var.environment}-db"
  engine         = "mysql"
  instance_class = "db.t3.micro"
  allocated_storage = 20
  
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
}
```

### Arquitetura Serverless

```hcl
# API Gateway
resource "aws_api_gateway_rest_api" "api" {
  name = "${var.environment}-api"
}

# Lambda Functions
resource "aws_lambda_function" "api_handler" {
  filename      = "lambda.zip"
  function_name = "${var.environment}-api-handler"
  role          = aws_iam_role.lambda.arn
  handler       = "index.handler"
  runtime       = "python3.9"
}

# DynamoDB
resource "aws_dynamodb_table" "data" {
  name     = "${var.environment}-data"
  hash_key = "id"
  
  attribute {
    name = "id"
    type = "S"
  }
}
```

---

## ✅ Checklist de Arquitetura

- [ ] Estrutura de diretórios definida
- [ ] Módulos criados para reutilização
- [ ] Ambientes separados (dev/staging/prod)
- [ ] Backend remoto configurado
- [ ] State locking habilitado
- [ ] Nomenclatura consistente
- [ ] Tags padronizadas
- [ ] Documentação de arquitetura
- [ ] Diagramas atualizados
- [ ] Plano de disaster recovery

---

## 🔗 Referências

- [Terraform Best Practices](./003-terraform-best-practices.md)
- [Terraform Modules](./007-terraform-modules.md)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)

---

**Última atualização:** 2026-01-23
