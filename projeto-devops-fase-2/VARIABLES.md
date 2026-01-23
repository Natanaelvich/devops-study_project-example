# 🔐 Configuração de Variáveis e Segurança

Este projeto usa variáveis do Terraform para manter informações sensíveis fora do código-fonte.

## ⚠️ Importante: Segurança

**NUNCA** commite os seguintes arquivos no Git:
- `terraform.tfvars` (contém valores sensíveis)
- `backend.hcl` (contém configurações do backend)
- `*.pem` (chaves privadas)
- `*.key` (arquivos de chave)

Esses arquivos já estão no `.gitignore` e serão ignorados automaticamente.

## 🚀 Configuração Inicial

### 1. Copie o arquivo de exemplo

```bash
cp terraform.tfvars.example terraform.tfvars
```

### 2. Edite o arquivo `terraform.tfvars`

Preencha com seus valores reais:

```hcl
# AWS Configuration
aws_region = "us-east-1"

# VPC Configuration
vpc_id = "vpc-xxxxxxxxx"  # Substitua pelo ID da sua VPC

# Security Configuration
ssh_allowed_ip = "200.106.133.23/32"  # Seu IP em formato CIDR
key_pair_name  = "sua-chave-aws"       # Nome da sua Key Pair na AWS

# Instance Configuration
instance_type = "t2.micro"
client_name   = "SeuNome"

# Terraform State Backend Configuration
terraform_state_bucket = "seu-bucket-terraform-state"
terraform_state_key    = "site/terraform.tfstate"

# ECR Configuration
ecr_repository_name = "site_prod"
```

### 3. Configure o Backend (Opcional)

O backend do Terraform não pode usar variáveis diretamente. Você tem duas opções:

#### Opção A: Configurar diretamente no `backend.tf`

Edite o arquivo `backend.tf` e descomente/configure os valores:

```hcl
terraform {
  backend "s3" {
    bucket  = "seu-bucket-terraform-state"
    key     = "site/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
```

#### Opção B: Usar arquivo de configuração separado

1. Copie o exemplo:
   ```bash
   cp backend.hcl.example backend.hcl
   ```

2. Edite `backend.hcl` com seus valores

3. Inicialize o Terraform com:
   ```bash
   terraform init -backend-config=backend.hcl
   ```

## 📋 Variáveis Disponíveis

### Variáveis Obrigatórias

| Variável | Descrição | Tipo | Sensível |
|----------|-----------|------|----------|
| `vpc_id` | ID da VPC onde os recursos serão criados | `string` | ✅ Sim |
| `key_pair_name` | Nome da AWS Key Pair para acesso SSH | `string` | ✅ Sim |
| `ssh_allowed_ip` | IP permitido para SSH (formato CIDR) | `string` | ✅ Sim |

### Variáveis Opcionais (com valores padrão)

| Variável | Descrição | Padrão |
|----------|-----------|--------|
| `aws_region` | Região AWS | `us-east-1` |
| `instance_type` | Tipo de instância EC2 | `t2.micro` |
| `client_name` | Nome do cliente para tags | `Default` |
| `ecr_repository_name` | Nome do repositório ECR | `site_prod` |
| `security_group_name` | Nome do Security Group | `website-sg` |
| `instance_name` | Nome da instância EC2 | `website-server` |
| `iam_role_name` | Nome da IAM Role | `ECR-EC2-Role` |

## 🔍 Como Descobrir Valores Necessários

### VPC ID

```bash
aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`].Value|[0]]' --output table
```

### Key Pair Name

```bash
aws ec2 describe-key-pairs --query 'KeyPairs[*].KeyName' --output table
```

### Seu IP Público

```bash
curl ifconfig.me
# Depois use: "SEU_IP/32"
```

## ✅ Verificação

Após configurar as variáveis, valide a configuração:

```bash
# Validar sintaxe
terraform validate

# Ver o plano (sem aplicar)
terraform plan

# Se tudo estiver OK, aplicar
terraform apply
```

## 🔄 Atualizando Variáveis

Se precisar alterar uma variável:

1. Edite `terraform.tfvars`
2. Execute `terraform plan` para ver as mudanças
3. Execute `terraform apply` para aplicar

## 📚 Mais Informações

- [Documentação Terraform - Variáveis](https://www.terraform.io/docs/language/values/variables.html)
- [Documentação Terraform - Backend](https://www.terraform.io/docs/language/settings/backends/index.html)
