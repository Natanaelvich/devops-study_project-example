# 🚀 Terraform Commands - Guia de Comandos Essenciais

Este documento lista os comandos Terraform mais utilizados no dia a dia, organizados por categoria.

**Profile AWS:** `terraform-study`  
**Região:** `us-east-1`

---

## 📑 Table of Contents

1. [Comandos Iniciais](#-comandos-iniciais)
2. [Comandos de Planejamento](#-comandos-de-planejamento)
3. [Comandos de Aplicação](#-comandos-de-aplicação)
4. [Comandos de Estado](#-comandos-de-estado)
5. [Comandos de Validação](#-comandos-de-validação)
6. [Comandos de Formatação](#-comandos-de-formatação)
7. [Comandos de Destruição](#-comandos-de-destruição)
8. [Comandos Avançados](#-comandos-avançados)
9. [Workflow Completo](#-workflow-completo)

---

## 🎯 Comandos Iniciais

### `terraform init`
Inicializa o diretório de trabalho do Terraform e configura o backend.

```bash
# Inicialização básica
terraform init

# Inicialização com reconexão do backend (se mudou configuração)
terraform init -reconfigure

# Inicialização com upgrade de providers
terraform init -upgrade

# Inicialização com migração de backend
terraform init -migrate-state
```

**Quando usar:**
- Primeira vez executando Terraform no projeto
- Após adicionar novos providers
- Após modificar configuração do backend
- Após clonar um repositório com Terraform

---

## 📋 Comandos de Planejamento

### `terraform plan`
Cria um plano de execução mostrando o que será criado, modificado ou destruído.

```bash
# Plano básico
terraform plan

# Salvar plano em arquivo
terraform plan -out=tfplan

# Usar plano salvo
terraform apply tfplan

# Plano detalhado (mais verboso)
terraform plan -detailed-exitcode

# Plano com variáveis
terraform plan -var="instance_type=t2.small"

# Plano com arquivo de variáveis
terraform plan -var-file="production.tfvars"

# Plano mostrando apenas recursos a serem destruídos
terraform plan -destroy
```

**Exit codes:**
- `0` = Sucesso, sem mudanças
- `1` = Erro
- `2` = Sucesso, com mudanças planejadas

---

## ✅ Comandos de Aplicação

### `terraform apply`
Aplica as mudanças planejadas.

```bash
# Aplicar com confirmação interativa
terraform apply

# Aplicar sem confirmação (auto-approve)
terraform apply -auto-approve

# Aplicar plano salvo
terraform apply tfplan

# Aplicar com variáveis
terraform apply -var="instance_type=t2.small"

# Aplicar com paralelismo limitado
terraform apply -parallelism=5
```

**⚠️ Atenção:** Sempre revise o `plan` antes de aplicar!

---

## 🔍 Comandos de Estado

### `terraform state`
Gerencia o estado do Terraform.

```bash
# Listar recursos no estado
terraform state list

# Mostrar detalhes de um recurso
terraform state show aws_instance.website_server

# Mover recurso (renomear no estado)
terraform state mv aws_instance.old_name aws_instance.new_name

# Remover recurso do estado (não destrói na AWS)
terraform state rm aws_instance.website_server

# Adicionar recurso existente ao estado
terraform import aws_instance.website_server i-1234567890abcdef0

# Listar outputs
terraform state list | grep output
```

### `terraform refresh`
Atualiza o estado com informações reais da infraestrutura.

```bash
# Atualizar estado
terraform refresh

# Atualizar estado e mostrar diferenças
terraform refresh -detailed-exitcode
```

---

## ✔️ Comandos de Validação

### `terraform validate`
Valida a sintaxe e configuração dos arquivos Terraform.

```bash
# Validação básica
terraform validate

# Validação com formatação JSON
terraform validate -json
```

**Quando usar:**
- Antes de fazer commit
- Em pipelines CI/CD
- Após modificar arquivos `.tf`

### `terraform fmt`
Formata os arquivos Terraform seguindo convenções.

```bash
# Formatar arquivos
terraform fmt

# Formatar recursivamente
terraform fmt -recursive

# Verificar sem modificar (modo check)
terraform fmt -check

# Listar arquivos que seriam formatados
terraform fmt -list=true
```

---

## 🗑️ Comandos de Destruição

### `terraform destroy`
Destrói todos os recursos gerenciados pelo Terraform.

```bash
# Destruir com confirmação
terraform destroy

# Destruir sem confirmação
terraform destroy -auto-approve

# Destruir recursos específicos (usando target)
terraform destroy -target=aws_instance.website_server

# Destruir com variáveis
terraform destroy -var="environment=dev"
```

**⚠️ Cuidado:** Este comando é irreversível!

---

## 🎓 Comandos Avançados

### `terraform workspace`
Gerencia workspaces (ambientes).

```bash
# Listar workspaces
terraform workspace list

# Criar novo workspace
terraform workspace new production

# Selecionar workspace
terraform workspace select production

# Mostrar workspace atual
terraform workspace show

# Deletar workspace
terraform workspace delete staging
```

### `terraform output`
Mostra valores de outputs.

```bash
# Listar todos os outputs
terraform output

# Mostrar output específico
terraform output instance_ip

# Formato JSON
terraform output -json

# Formato raw (apenas valor)
terraform output -raw instance_ip
```

### `terraform console`
Abre console interativo para testar expressões.

```bash
# Abrir console
terraform console

# Exemplos de uso no console:
# > aws_instance.website_server.id
# > var.instance_type
# > data.aws_ami.amazon_linux.id
```

### `terraform graph`
Gera visualização de dependências.

```bash
# Gerar gráfico
terraform graph

# Salvar em arquivo DOT
terraform graph > graph.dot

# Visualizar (requer Graphviz)
terraform graph | dot -Tsvg > graph.svg
```

---

## 🔄 Workflow Completo

### Fluxo de trabalho recomendado:

```bash
# 1. Inicializar (primeira vez ou após mudanças)
terraform init

# 2. Validar sintaxe
terraform validate

# 3. Formatar código
terraform fmt

# 4. Criar plano
terraform plan -out=tfplan

# 5. Revisar plano (manualmente)

# 6. Aplicar mudanças
terraform apply tfplan

# 7. Verificar outputs
terraform output

# 8. Verificar estado
terraform state list
```

### Workflow com variáveis:

```bash
# Criar arquivo de variáveis
cat > terraform.tfvars <<EOF
instance_type = "t2.micro"
region        = "us-east-1"
environment   = "production"
EOF

# Usar variáveis
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

### Workflow com workspaces:

```bash
# Criar workspace para desenvolvimento
terraform workspace new dev
terraform plan
terraform apply

# Mudar para produção
terraform workspace select prod
terraform plan
terraform apply
```

---

## 🛠️ Comandos Úteis Adicionais

### Verificar versão
```bash
terraform version
```

### Limpar cache de providers
```bash
rm -rf .terraform
terraform init
```

### Forçar unlock do state (se travado)
```bash
terraform force-unlock <LOCK_ID>
```

### Mostrar providers usados
```bash
terraform providers
```

### Validar e formatar em um comando
```bash
terraform fmt -check && terraform validate
```

---

## 📝 Dicas Importantes

1. **Sempre faça `terraform plan` antes de `apply`**
2. **Use `-out` para salvar planos** e revisar antes de aplicar
3. **Valide e formate** antes de fazer commit
4. **Use workspaces** para gerenciar múltiplos ambientes
5. **Documente variáveis** com `description` nos arquivos `.tf`
6. **Use `.tfvars`** para valores específicos de ambiente
7. **Nunca edite o state manualmente** - use comandos do Terraform
8. **Faça backup do state** antes de operações críticas

---

## 🔗 Comandos Relacionados

- [Terraform Best Practices](./003-terraform-best-practices.md)
- [Terraform State Management](./006-terraform-state-management.md)
- [Terraform Troubleshooting](./005-terraform-troubleshooting.md)

---

**Última atualização:** 2026-01-23
