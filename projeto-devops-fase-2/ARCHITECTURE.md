# 🏗️ Arquitetura do Projeto

Este projeto segue as melhores práticas de arquitetura Terraform conforme documentado no guia de arquiteturas recomendadas.

## 📁 Estrutura do Projeto

```
projeto-devops-fase-2/
├── .docs/                          # Documentação completa
├── modules/                        # Módulos reutilizáveis
│   ├── ec2/                       # Módulo de instâncias EC2
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── security-group/             # Módulo de Security Groups
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── ecr/                       # Módulo de ECR repositories
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── iam/                       # Módulo de IAM roles
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── main.tf                        # Arquivo principal que usa os módulos
├── variables.tf                   # Variáveis do projeto
├── outputs.tf                     # Outputs do projeto
├── locals.tf                      # Tags comuns e valores compartilhados
├── data.tf                        # Data sources
├── provider.tf                    # Configuração do provider AWS
├── backend.tf                     # Configuração do backend (S3)
├── terraform.tfvars.example       # Template de variáveis
├── backend.hcl.example            # Template de backend config
├── VARIABLES.md                   # Documentação de variáveis
└── ARCHITECTURE.md                # Este arquivo
```

## 🧩 Módulos

### Módulo IAM (`modules/iam/`)
Cria IAM role e instance profile para permitir que instâncias EC2 acessem o ECR.

**Recursos:**
- `aws_iam_role` - Role para EC2 acessar ECR
- `aws_iam_role_policy_attachment` - Anexa política de leitura do ECR
- `aws_iam_instance_profile` - Profile para anexar à EC2

**Outputs:**
- `role_name` - Nome da role
- `role_arn` - ARN da role
- `instance_profile_name` - Nome do instance profile
- `instance_profile_arn` - ARN do instance profile

### Módulo Security Group (`modules/security-group/`)
Cria security group com regras de ingress e egress configuráveis.

**Recursos:**
- `aws_security_group` - Security group principal
- `aws_vpc_security_group_ingress_rule` - Regras de entrada (SSH, HTTP, HTTPS)
- `aws_vpc_security_group_egress_rule` - Regra de saída (all traffic)

**Outputs:**
- `security_group_id` - ID do security group
- `security_group_arn` - ARN do security group
- `security_group_name` - Nome do security group

### Módulo EC2 (`modules/ec2/`)
Cria instâncias EC2 com configurações personalizáveis.

**Recursos:**
- `aws_instance` - Instância EC2

**Outputs:**
- `instance_id` - ID da instância
- `instance_arn` - ARN da instância
- `private_ip` - IP privado
- `public_ip` - IP público
- `public_dns` - DNS público

### Módulo ECR (`modules/ecr/`)
Cria repositórios ECR para armazenar imagens Docker.

**Recursos:**
- `aws_ecr_repository` - Repositório ECR

**Outputs:**
- `repository_url` - URL do repositório
- `repository_arn` - ARN do repositório
- `repository_name` - Nome do repositório

## 🏷️ Tags Padronizadas

O projeto usa tags padronizadas definidas em `locals.tf`:

```hcl
{
  Environment = var.environment    # dev, staging, prod
  Project     = "laboratorio-devops"
  ManagedBy   = "Terraform"
  Cliente     = var.client_name
  CreatedAt   = timestamp()
}
```

## 📝 Nomenclatura de Recursos

Os recursos seguem o padrão: `{environment}-{project_name}-{resource-type}`

Exemplos:
- `dev-website-ecr-role` - IAM role no ambiente dev
- `dev-website-sg` - Security group no ambiente dev
- `dev-website-server` - Instância EC2 no ambiente dev

Você pode sobrescrever os nomes usando as variáveis opcionais:
- `security_group_name`
- `instance_name`
- `iam_role_name`

## 🔄 Fluxo de Dependências

```
data.tf (AMI lookup)
    ↓
main.tf
    ├──→ module.iam
    │       └──→ IAM Role + Instance Profile
    │
    ├──→ module.security_group
    │       └──→ Security Group + Rules
    │
    ├──→ module.ec2
    │       ├──→ Uses: module.iam.instance_profile_name
    │       └──→ Uses: module.security_group.security_group_id
    │
    └──→ module.ecr
            └──→ ECR Repository
```

## 🌍 Suporte a Múltiplos Ambientes

O projeto suporta múltiplos ambientes através da variável `environment`:

- **dev** - Ambiente de desenvolvimento
- **staging** - Ambiente de staging
- **prod** - Ambiente de produção

Cada ambiente pode ter seu próprio arquivo `terraform.tfvars`:
- `terraform.tfvars.dev`
- `terraform.tfvars.staging`
- `terraform.tfvars.prod`

## 🚀 Como Usar

1. **Configure as variáveis:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edite terraform.tfvars com seus valores
   ```

2. **Inicialize o Terraform:**
   ```bash
   terraform init
   ```

3. **Valide a configuração:**
   ```bash
   terraform validate
   terraform fmt
   ```

4. **Veja o plano:**
   ```bash
   terraform plan
   ```

5. **Aplique as mudanças:**
   ```bash
   terraform apply
   ```

## 📚 Documentação Adicional

- [VARIABLES.md](./VARIABLES.md) - Guia completo de variáveis
- [.docs/004-terraform-best-architectures.md](./.docs/004-terraform-best-architectures.md) - Guia de arquiteturas
- [.docs/007-terraform-modules.md](./.docs/007-terraform-modules.md) - Guia de módulos

## ✅ Benefícios desta Arquitetura

1. **Modularidade** - Código reutilizável e organizado
2. **Manutenibilidade** - Fácil de entender e modificar
3. **Escalabilidade** - Fácil adicionar novos recursos
4. **Consistência** - Tags e nomenclatura padronizadas
5. **Testabilidade** - Módulos podem ser testados isoladamente
6. **Multi-ambiente** - Suporte nativo para múltiplos ambientes
