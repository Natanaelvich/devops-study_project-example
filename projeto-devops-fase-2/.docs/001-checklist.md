# ✅ Checklist - Pré-requisitos AWS

Este checklist contém todos os recursos AWS que **devem estar criados manualmente** antes de executar o Terraform.

**Região:** `us-east-1` (conforme `provider.tf`)  
**Profile AWS:** `terraform-study`

---

## 📑 Table of Contents

1. [S3 Bucket para Terraform State](#-1-s3-bucket-para-terraform-state)
2. [EC2 Key Pair](#-2-ec2-key-pair)
3. [VPC](#-3-vpc)
4. [IAM Instance Profile](#-4-iam-instance-profile)
5. [AMI (Amazon Machine Image)](#️-5-ami-amazon-machine-image)
6. [Permissões IAM do Usuário/Role Executando Terraform](#-6-permissões-iam-do-usuáriorole-executando-terraform)
7. [Resumo](#-resumo)
8. [Próximos Passos](#-próximos-passos)

---

## 📦 1. S3 Bucket para Terraform State

**Arquivo:** `backend.tf`

- [ ] **Bucket criado:** `terraform-state-natanaelvich`
- [ ] **Região:** `us-east-1`
- [ ] **Versionamento habilitado**
- [ ] **Criptografia habilitada** (SSE-S3 ou SSE-KMS)
- [ ] **Política de acesso configurada** para o usuário/role que executará o Terraform

**Comandos:**
```bash
# Criar bucket
aws s3 mb s3://terraform-state-natanaelvich --region us-east-1 --profile terraform-study

# Habilitar versionamento
aws s3api put-bucket-versioning \
  --bucket terraform-state-natanaelvich \
  --versioning-configuration Status=Enabled \
  --region us-east-1 \
  --profile terraform-study

# Habilitar criptografia
aws s3api put-bucket-encryption \
  --bucket terraform-state-natanaelvich \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }' \
  --region us-east-1 \
  --profile terraform-study

# Verificar
aws s3 ls s3://terraform-state-natanaelvich --region us-east-1 --profile terraform-study
```

---

## 🔑 2. EC2 Key Pair

**Arquivo:** `ec2.tf` (linha 4)

- [ ] **Key Pair criada:** `chave-site-prod`
- [ ] **Região:** `us-east-1`
- [ ] **Arquivo `.pem` salvo localmente** com permissões corretas (chmod 400)

**Comandos:**
```bash
# Criar key pair
aws ec2 create-key-pair \
  --key-name chave-site-prod \
  --region us-east-1 \
  --profile terraform-study \
  --query 'KeyMaterial' \
  --output text > chave-site-prod.pem

# Ajustar permissões
chmod 400 chave-site-prod.pem

# Verificar
aws ec2 describe-key-pairs \
  --key-names chave-site-prod \
  --region us-east-1 \
  --profile terraform-study
```

---

## 🌐 3. VPC

**Arquivo:** `ec2.tf` (linha 18)

- [ ] **VPC existe:** `vpc-0ff60a695425883cf`
- [ ] **Região:** `us-east-1`
- [ ] **Subnets configuradas** (pelo menos uma subnet pública)
- [ ] **Internet Gateway anexado** (se a instância precisar de acesso à internet)
- [ ] **Route Tables configuradas** (rotas para internet gateway)

**Comandos:**
```bash
# Verificar se VPC existe
aws ec2 describe-vpcs \
  --vpc-ids vpc-0ff60a695425883cf \
  --region us-east-1 \
  --profile terraform-study

# Verificar subnets
aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=vpc-0ff60a695425883cf" \
  --region us-east-1 \
  --profile terraform-study

# Verificar Internet Gateway
aws ec2 describe-internet-gateways \
  --filters "Name=attachment.vpc-id,Values=vpc-0ff60a695425883cf" \
  --region us-east-1 \
  --profile terraform-study
```

---

## 👤 4. IAM Instance Profile

**Arquivo:** `ec2.tf` (linha 6)

- [ ] **IAM Role criada:** `ECR-EC2-Role`
- [ ] **Trust Policy configurada** (permite EC2 assumir a role)
- [ ] **Permissões ECR anexadas** (para pull de imagens)
- [ ] **Instance Profile criado:** `ECR-EC2-Role`
- [ ] **Role adicionada ao Instance Profile**

**Permissões ECR necessárias:**
- `ecr:GetAuthorizationToken`
- `ecr:BatchCheckLayerAvailability`
- `ecr:GetDownloadUrlForLayer`
- `ecr:BatchGetImage`
- `ecr:DescribeRepositories`
- `ecr:ListImages`

**Comandos:**
```bash
# Criar IAM Role
aws iam create-role \
  --role-name ECR-EC2-Role \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "ec2.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }' \
  --profile terraform-study

# Anexar política ECR (política gerenciada da AWS)
aws iam attach-role-policy \
  --role-name ECR-EC2-Role \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly \
  --profile terraform-study

# Criar Instance Profile
aws iam create-instance-profile \
  --instance-profile-name ECR-EC2-Role \
  --profile terraform-study

# Adicionar role ao instance profile
aws iam add-role-to-instance-profile \
  --instance-profile-name ECR-EC2-Role \
  --role-name ECR-EC2-Role \
  --profile terraform-study

# Verificar
aws iam get-instance-profile \
  --instance-profile-name ECR-EC2-Role \
  --profile terraform-study
```

---

## 🖼️ 5. AMI (Amazon Machine Image)

**Arquivo:** `ec2.tf` (linha 2)

- [ ] **AMI existe:** `ami-0b016c703b95ecbe4`
- [ ] **Região:** `us-east-1`
- [ ] **AMI está disponível** (não descontinuada)

**Comandos:**
```bash
# Verificar se AMI existe
aws ec2 describe-images \
  --image-ids ami-0b016c703b95ecbe4 \
  --region us-east-1 \
  --profile terraform-study

# Se não existir, buscar AMI Amazon Linux 2 mais recente
aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" \
            "Name=state,Values=available" \
  --query 'Images | sort_by(@, &CreationDate) | [-1].[ImageId,Name,CreationDate]' \
  --output table \
  --region us-east-1 \
  --profile terraform-study
```

**Se a AMI não existir:** Atualizar o `ami` no arquivo `ec2.tf` com uma AMI válida.

---

## 🔐 6. Permissões IAM do Usuário/Role Executando Terraform

**Arquivo:** `terraform-iam-policy.json`

- [ ] **Usuário/Role tem permissões** conforme `terraform-iam-policy.json`
- [ ] **Política anexada** ao usuário/role que executará o Terraform
- [ ] **Permissões testadas** (pelo menos `aws sts get-caller-identity` funciona)

**Comandos:**
```bash
# Verificar identidade atual
aws sts get-caller-identity --profile terraform-study

# Anexar política (exemplo - ajustar conforme necessário)
aws iam put-user-policy \
  --user-name SEU_USUARIO \
  --policy-name TerraformPolicy \
  --policy-document file://terraform-iam-policy.json \
  --profile terraform-study
```

---

## 📝 Resumo

**Total de recursos obrigatórios:** 5

1. ✅ S3 Bucket: `terraform-state-natanaelvich`
2. ✅ EC2 Key Pair: `chave-site-prod`
3. ✅ VPC: `vpc-0ff60a695425883cf`
4. ✅ IAM Instance Profile: `ECR-EC2-Role`
5. ✅ AMI: `ami-0b016c703b95ecbe4` (verificar existência)

**Recursos criados pelo Terraform (não precisa criar):**
- ECR Repository (`site_prod`)
- Security Group (`website-sg`)
- EC2 Instance (`website-server`)

---

## 🚀 Próximos Passos

Após completar este checklist:

1. Execute `terraform init` para inicializar o backend
2. Execute `terraform plan` para verificar o plano de execução
3. Execute `terraform apply` para criar os recursos

---

**Última atualização:** 2026-01-23
