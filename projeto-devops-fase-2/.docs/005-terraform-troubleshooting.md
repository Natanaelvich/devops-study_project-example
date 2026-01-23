# 🔧 Terraform Troubleshooting - Solução de Problemas

Este documento lista problemas comuns ao trabalhar com Terraform e suas soluções.

---

## 📑 Table of Contents

1. [Problemas de Inicialização](#-problemas-de-inicialização)
2. [Problemas de Estado](#-problemas-de-estado)
3. [Problemas de Provider](#-problemas-de-provider)
4. [Problemas de Aplicação](#-problemas-de-aplicação)
5. [Problemas de Autenticação](#-problemas-de-autenticação)
6. [Problemas de Recursos](#-problemas-de-recursos)
7. [Problemas de Performance](#-problemas-de-performance)
8. [Comandos de Debug](#-comandos-de-debug)

---

## 🚀 Problemas de Inicialização

### Erro: "Backend configuration changed"

**Sintoma:**
```
Error: Backend configuration changed
```

**Solução:**
```bash
# Reconfigurar backend
terraform init -reconfigure
```

### Erro: "Provider requirements"

**Sintoma:**
```
Error: Could not satisfy plugin requirements
```

**Solução:**
```bash
# Atualizar providers
terraform init -upgrade

# Ou limpar cache e reinicializar
rm -rf .terraform
terraform init
```

### Erro: "Lock file"

**Sintoma:**
```
Error: Error acquiring the state lock
```

**Solução:**
```bash
# Verificar lock
terraform force-unlock <LOCK_ID>

# ⚠️ CUIDADO: Só use se tiver certeza que não há outra execução
```

---

## 💾 Problemas de Estado

### Estado Desatualizado

**Sintoma:**
Terraform tenta criar recursos que já existem.

**Solução:**
```bash
# Atualizar estado com recursos reais
terraform refresh

# Ou importar recurso existente
terraform import aws_instance.server i-1234567890abcdef0
```

### Estado Corrompido

**Sintoma:**
Erros ao ler o state file.

**Solução:**
```bash
# Fazer backup do state
cp terraform.tfstate terraform.tfstate.backup

# Tentar validar
terraform validate

# Se necessário, restaurar do backup do S3
aws s3 cp s3://terraform-state-natanaelvich/site/terraform.tfstate.backup terraform.tfstate
```

### Recursos Não Encontrados no Estado

**Sintoma:**
```
Error: resource not found in state
```

**Solução:**
```bash
# Remover do estado (não destrói na AWS)
terraform state rm aws_instance.old_name

# Reimportar se necessário
terraform import aws_instance.new_name i-1234567890abcdef0
```

---

## 🔌 Problemas de Provider

### Erro: "Provider not found"

**Sintoma:**
```
Error: Failed to query available provider packages
```

**Solução:**
```bash
# Verificar versão do Terraform
terraform version

# Atualizar providers
terraform init -upgrade

# Verificar versão do provider no código
# Deve estar em versions.tf ou provider.tf
```

### Erro: "Provider version constraint"

**Sintoma:**
```
Error: Incompatible provider version
```

**Solução:**
```hcl
# Atualizar constraint no código
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"  # Ajustar versão
    }
  }
}

# Depois executar
terraform init -upgrade
```

---

## ⚙️ Problemas de Aplicação

### Erro: "Resource already exists"

**Sintoma:**
```
Error: Error creating resource: already exists
```

**Solução:**
```bash
# Importar recurso existente
terraform import aws_instance.server i-1234567890abcdef0

# Ou remover do código e adicionar como data source
```

### Erro: "Dependency violation"

**Sintoma:**
```
Error: DependencyViolation: resource is in use
```

**Solução:**
```bash
# Verificar dependências
terraform graph | grep <resource_name>

# Usar -target para aplicar recursos específicos primeiro
terraform apply -target=aws_security_group.web
terraform apply
```

### Erro: "Timeout"

**Sintoma:**
```
Error: timeout while waiting for state to become 'available'
```

**Solução:**
```hcl
# Aumentar timeout no recurso
resource "aws_db_instance" "main" {
  # ...
  
  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}
```

---

## 🔐 Problemas de Autenticação

### Erro: "No valid credential sources"

**Sintoma:**
```
Error: No valid credential sources found
```

**Solução:**
```bash
# Verificar profile
aws configure list --profile terraform-study

# Testar credenciais
aws sts get-caller-identity --profile terraform-study

# Configurar variáveis de ambiente (alternativa)
export AWS_PROFILE=terraform-study
export AWS_REGION=us-east-1
```

### Erro: "Access Denied"

**Sintoma:**
```
Error: AccessDenied: User is not authorized
```

**Solução:**
```bash
# Verificar permissões
aws iam get-user --profile terraform-study

# Verificar políticas anexadas
aws iam list-attached-user-policies --user-name <user> --profile terraform-study

# Usar política do arquivo terraform-iam-policy.json
```

### Erro: "Token expired" (SSO)

**Sintoma:**
```
Error: Token has expired and refresh failed
```

**Solução:**
```bash
# Fazer login SSO novamente
aws sso login --profile natanael-profile

# Ou usar profile com access keys
aws configure --profile terraform-study
```

---

## 📦 Problemas de Recursos

### Erro: "AMI not found"

**Sintoma:**
```
Error: InvalidAMIID.NotFound
```

**Solução:**
```bash
# Verificar AMI na região
aws ec2 describe-images \
  --image-ids ami-0b016c703b95ecbe4 \
  --region us-east-1 \
  --profile terraform-study

# Buscar AMI válida
aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" \
  --region us-east-1 \
  --profile terraform-study
```

### Erro: "VPC not found"

**Sintoma:**
```
Error: InvalidVpcID.NotFound
```

**Solução:**
```bash
# Verificar VPC existe
aws ec2 describe-vpcs \
  --vpc-ids vpc-b2083cc8 \
  --region us-east-1 \
  --profile terraform-study

# Listar VPCs disponíveis
aws ec2 describe-vpcs --region us-east-1 --profile terraform-study
```

### Erro: "Key pair not found"

**Sintoma:**
```
Error: InvalidKeyPair.NotFound
```

**Solução:**
```bash
# Verificar key pair
aws ec2 describe-key-pairs \
  --key-names chave-site-prod \
  --region us-east-1 \
  --profile terraform-study

# Criar key pair se não existir
aws ec2 create-key-pair \
  --key-name chave-site-prod \
  --region us-east-1 \
  --profile terraform-study
```

---

## ⚡ Problemas de Performance

### Terraform muito lento

**Sintoma:**
Terraform demora muito para planejar ou aplicar.

**Solução:**
```bash
# Limitar paralelismo
terraform apply -parallelism=5

# Usar -refresh=false se estado está atualizado
terraform plan -refresh=false

# Verificar dependências desnecessárias
terraform graph | dot -Tsvg > graph.svg
```

### Rate Limits da AWS

**Sintoma:**
```
Error: Throttling: Rate exceeded
```

**Solução:**
```bash
# Reduzir paralelismo
terraform apply -parallelism=3

# Adicionar delays (usar null_resource com local-exec)
resource "null_resource" "delay" {
  provisioner "local-exec" {
    command = "sleep 5"
  }
}
```

---

## 🐛 Comandos de Debug

### Modo Verbose

```bash
# Aplicar com logs detalhados
TF_LOG=DEBUG terraform apply

# Salvar logs em arquivo
TF_LOG=DEBUG terraform apply 2>&1 | tee terraform.log
```

### Validar Configuração

```bash
# Validar sintaxe
terraform validate

# Validar com JSON
terraform validate -json
```

### Verificar Dependências

```bash
# Gerar gráfico de dependências
terraform graph | dot -Tpng > graph.png

# Ver recursos no estado
terraform state list

# Ver detalhes de recurso
terraform state show aws_instance.website_server
```

### Testar Expressões

```bash
# Abrir console interativo
terraform console

# Testar expressões
> aws_instance.website_server.id
> var.instance_type
> data.aws_ami.amazon_linux.id
```

---

## 📋 Checklist de Troubleshooting

Quando encontrar um erro:

1. [ ] Ler a mensagem de erro completa
2. [ ] Verificar logs com `TF_LOG=DEBUG`
3. [ ] Validar configuração: `terraform validate`
4. [ ] Verificar estado: `terraform state list`
5. [ ] Verificar credenciais: `aws sts get-caller-identity`
6. [ ] Verificar recursos na AWS: `aws ec2 describe-instances`
7. [ ] Consultar documentação do provider
8. [ ] Verificar versões: `terraform version`
9. [ ] Tentar refresh: `terraform refresh`
10. [ ] Verificar dependências: `terraform graph`

---

## 🔗 Referências

- [Terraform Commands](./002-terraform-commands.md)
- [Terraform State Management](./006-terraform-state-management.md)
- [Documentação Oficial - Troubleshooting](https://www.terraform.io/docs/cli/commands/index.html)

---

## 💡 Dicas Finais

1. **Sempre faça backup do state** antes de operações críticas
2. **Use versionamento** no bucket S3 do state
3. **Documente mudanças** no código
4. **Teste em dev** antes de aplicar em prod
5. **Use workspaces** para isolar ambientes
6. **Mantenha logs** de execuções importantes

---

**Última atualização:** 2026-01-23
