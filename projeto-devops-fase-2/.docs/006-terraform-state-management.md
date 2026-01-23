# 💾 Terraform State Management - Gerenciamento de Estado

Este documento explica como gerenciar o estado do Terraform de forma eficiente e segura.

---

## 📑 Table of Contents

1. [O que é State?](#-o-que-é-state)
2. [Backend Remoto](#-backend-remoto)
3. [State Locking](#-state-locking)
4. [Workspaces](#-workspaces)
5. [Operações de Estado](#-operações-de-estado)
6. [Backup e Recuperação](#-backup-e-recuperação)
7. [State Sensitive Data](#-state-sensitive-data)
8. [Best Practices](#-best-practices)

---

## 📖 O que é State?

O **state** é um arquivo que armazena o mapeamento entre recursos no código Terraform e recursos reais na infraestrutura.

### Por que o State é Importante?

- **Mapeamento**: Liga recursos no código aos IDs reais na AWS
- **Metadata**: Armazena atributos de recursos
- **Dependências**: Mantém informações sobre dependências entre recursos
- **Performance**: Permite planejamento rápido sem consultar a AWS

### Local vs Remote State

```hcl
# ❌ State Local (não recomendado para produção)
# Armazenado em terraform.tfstate no diretório local

# ✅ State Remoto (recomendado)
terraform {
  backend "s3" {
    bucket = "terraform-state-natanaelvich"
    key    = "site/terraform.tfstate"
    region = "us-east-1"
  }
}
```

---

## ☁️ Backend Remoto

### Configuração S3 Backend

```hcl
# backend.tf
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

### Migração de State Local para Remoto

```bash
# 1. Configurar backend no código
# 2. Inicializar
terraform init

# 3. Terraform perguntará se deseja migrar
# Responda: yes

# Ou forçar migração
terraform init -migrate-state
```

### Mudança de Backend

```bash
# Se mudou configuração do backend
terraform init -reconfigure
```

---

## 🔒 State Locking

### Por que State Locking?

Previne execuções simultâneas do Terraform que podem corromper o state.

### Configuração com DynamoDB

```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state-natanaelvich"
    key            = "site/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"  # ⬅️ Importante!
  }
}
```

### Criar Tabela DynamoDB

```bash
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1 \
  --profile terraform-study
```

### Forçar Unlock (Cuidado!)

```bash
# ⚠️ Só use se tiver certeza que não há outra execução
terraform force-unlock <LOCK_ID>

# Obter LOCK_ID da mensagem de erro
```

---

## 🌍 Workspaces

### O que são Workspaces?

Workspaces permitem múltiplos states no mesmo backend, útil para ambientes diferentes.

### Gerenciar Workspaces

```bash
# Listar workspaces
terraform workspace list

# Criar novo workspace
terraform workspace new dev

# Selecionar workspace
terraform workspace select dev

# Mostrar workspace atual
terraform workspace show

# Deletar workspace
terraform workspace delete staging
```

### Usar Workspaces no Código

```hcl
# Usar workspace atual
resource "aws_instance" "server" {
  tags = {
    Environment = terraform.workspace
  }
}

# Condicionais baseadas em workspace
locals {
  instance_type = terraform.workspace == "prod" ? "t2.large" : "t2.micro"
}
```

### Backend com Workspaces

```hcl
terraform {
  backend "s3" {
    bucket = "terraform-state-natanaelvich"
    key    = "site/${terraform.workspace}/terraform.tfstate"  # ⬅️ Workspace no path
    region = "us-east-1"
  }
}
```

---

## 🔧 Operações de Estado

### Listar Recursos

```bash
# Listar todos os recursos
terraform state list

# Filtrar recursos
terraform state list | grep aws_instance
```

### Mostrar Recurso

```bash
# Detalhes completos de um recurso
terraform state show aws_instance.website_server
```

### Mover Recurso

```bash
# Renomear recurso no state (não destrói na AWS)
terraform state mv aws_instance.old_name aws_instance.new_name

# Mover para módulo
terraform state mv aws_instance.server module.ec2.aws_instance.server
```

### Remover do Estado

```bash
# Remover do state (NÃO destrói na AWS)
terraform state rm aws_instance.website_server

# Útil quando:
# - Recurso foi movido para outro Terraform
# - Recurso foi deletado manualmente na AWS
# - Recurso não deve mais ser gerenciado
```

### Importar Recurso

```bash
# Adicionar recurso existente ao state
terraform import aws_instance.website_server i-1234567890abcdef0

# Sintaxe: terraform import <resource_type>.<resource_name> <resource_id>
```

### Atualizar Estado

```bash
# Atualizar state com estado real da infraestrutura
terraform refresh

# Refresh sem modificar recursos
terraform plan -refresh-only
```

---

## 💾 Backup e Recuperação

### Backup Automático

O S3 com versionamento mantém histórico automaticamente:

```bash
# Habilitar versionamento no bucket
aws s3api put-bucket-versioning \
  --bucket terraform-state-natanaelvich \
  --versioning-configuration Status=Enabled \
  --region us-east-1 \
  --profile terraform-study
```

### Listar Versões

```bash
# Listar versões do state
aws s3api list-object-versions \
  --bucket terraform-state-natanaelvich \
  --prefix site/terraform.tfstate \
  --region us-east-1 \
  --profile terraform-study
```

### Restaurar Versão Anterior

```bash
# 1. Listar versões
aws s3api list-object-versions \
  --bucket terraform-state-natanaelvich \
  --prefix site/terraform.tfstate \
  --region us-east-1 \
  --profile terraform-study

# 2. Baixar versão específica
aws s3api get-object \
  --bucket terraform-state-natanaelvich \
  --key site/terraform.tfstate \
  --version-id <VERSION_ID> \
  terraform.tfstate.backup \
  --region us-east-1 \
  --profile terraform-study

# 3. Restaurar (se necessário)
# Fazer backup do state atual primeiro!
```

### Backup Manual

```bash
# Fazer backup antes de operações críticas
aws s3 cp \
  s3://terraform-state-natanaelvich/site/terraform.tfstate \
  s3://terraform-state-natanaelvich/backups/terraform.tfstate.$(date +%Y%m%d-%H%M%S) \
  --region us-east-1 \
  --profile terraform-study
```

---

## 🔐 State Sensitive Data

### Dados Sensíveis no State

O state pode conter dados sensíveis (senhas, tokens, etc.).

### Proteção

```hcl
# Marcar outputs como sensíveis
output "database_password" {
  value     = aws_db_instance.main.password
  sensitive = true  # ⬅️ Não será exibido no terminal
}
```

### Criptografia

```hcl
# Backend com criptografia
terraform {
  backend "s3" {
    bucket         = "terraform-state-natanaelvich"
    key            = "site/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true  # ⬅️ Criptografia no S3
    kms_key_id     = "arn:aws:kms:..."  # Opcional: KMS key
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
```

---

## ✅ Best Practices

### 1. Sempre Use Backend Remoto

```hcl
# ✅ BOM
terraform {
  backend "s3" {
    # ...
  }
}

# ❌ RUIM
# State local (terraform.tfstate)
```

### 2. Habilite State Locking

```hcl
terraform {
  backend "s3" {
    dynamodb_table = "terraform-state-lock"  # ⬅️ Sempre!
  }
}
```

### 3. Use Versionamento no S3

```bash
# Habilitar versionamento
aws s3api put-bucket-versioning \
  --bucket terraform-state-natanaelvich \
  --versioning-configuration Status=Enabled
```

### 4. Separe States por Ambiente

```hcl
# Opção 1: Workspaces
key = "site/${terraform.workspace}/terraform.tfstate"

# Opção 2: Diretórios separados
# environments/dev/backend.tf
key = "dev/terraform.tfstate"

# environments/prod/backend.tf
key = "prod/terraform.tfstate"
```

### 5. Faça Backups Regulares

```bash
# Script de backup automático
#!/bin/bash
DATE=$(date +%Y%m%d-%H%M%S)
aws s3 cp \
  s3://terraform-state-natanaelvich/site/terraform.tfstate \
  s3://terraform-state-natanaelvich/backups/terraform.tfstate.$DATE
```

### 6. Não Edite State Manualmente

```bash
# ❌ NUNCA faça isso
# vim terraform.tfstate

# ✅ Use comandos do Terraform
terraform state mv ...
terraform state rm ...
```

### 7. Use Criptografia

```hcl
terraform {
  backend "s3" {
    encrypt = true  # ⬅️ Sempre!
  }
}
```

---

## 📋 Checklist de State Management

- [ ] Backend remoto configurado (S3)
- [ ] State locking habilitado (DynamoDB)
- [ ] Versionamento habilitado no S3
- [ ] Criptografia habilitada
- [ ] States separados por ambiente
- [ ] Backup automático configurado
- [ ] .gitignore configurado (não commitar state)
- [ ] Outputs sensíveis marcados
- [ ] Documentação de recuperação criada

---

## 🔗 Referências

- [Terraform Commands](./002-terraform-commands.md)
- [Terraform Best Practices](./003-terraform-best-practices.md)
- [Terraform Troubleshooting](./005-terraform-troubleshooting.md)
- [Documentação Oficial - State](https://www.terraform.io/docs/language/state/index.html)

---

**Última atualização:** 2026-01-23
