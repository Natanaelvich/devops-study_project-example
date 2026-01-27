# Políticas IAM para push no ECR

## Arquivos

| Arquivo | Uso |
|---------|-----|
| `ecr-push-policy.json` | Permissões **apenas** para o repositório `site_prod` em `us-east-1` |
| `ecr-push-policy-all-repos.json` | Permissões para **todos** os repositórios ECR da conta |

## Como usar

### 1. Substituir o placeholder

Antes de criar a política na AWS, troque **`ACCOUNT_ID`** pelo ID da sua conta (ex.: `867118092958`):

```bash
# Ver seu Account ID
aws sts get-caller-identity --query Account --output text

# Substituir no arquivo (Linux/Mac)
sed -i.bak 's/ACCOUNT_ID/867118092958/g' ecr-push-policy.json
```

### 2. Criar a política no IAM

```bash
aws iam create-policy \
  --policy-name ECRPushSiteProd \
  --policy-document file://ecr-push-policy.json \
  --description "Permissões para push de imagens no ECR (site_prod)"
```

### 3. Anexar ao usuário ou role

**Anexar a um usuário IAM:**

```bash
aws iam attach-user-policy \
  --user-name SEU_USUARIO \
  --policy-arn arn:aws:iam::ACCOUNT_ID:policy/ECRPushSiteProd
```

**Ou criar uma policy inline na sua user/role pelo console AWS:**  
IAM → Users → seu usuário → Add permissions → Create inline policy → JSON → cole o conteúdo (já com ACCOUNT_ID trocado).

## Permissões incluídas

| Ação | Necessidade |
|------|-------------|
| `ecr:GetAuthorizationToken` | Login do Docker no ECR (`docker login` via CLI) |
| `ecr:BatchCheckLayerAvailability` | Verificar camadas durante o push |
| `ecr:PutImage` | Enviar a imagem |
| `ecr:InitiateLayerUpload` | Iniciar upload de camada |
| `ecr:UploadLayerPart` | Enviar partes da camada |
| `ecr:CompleteLayerUpload` | Finalizar upload de camada |
| `ecr:DescribeRepositories` | Usado pelo script para verificar se o repo existe |
| `ecr:DescribeImages` / `ecr:ListImages` | Listar imagens (útil para debug) |
| `ecr:GetDownloadUrlForLayer` / `ecr:BatchGetImage` | Pull (útil se o mesmo usuário fizer pull) |

## Mínimo para só push

Se quiser o **mínimo estrito** (apenas push, sem describe/list), use só:

- `ecr:GetAuthorizationToken` (Resource: `*`)
- `ecr:BatchCheckLayerAvailability`, `ecr:PutImage`, `ecr:InitiateLayerUpload`, `ecr:UploadLayerPart`, `ecr:CompleteLayerUpload` no repositório desejado

O script `push-ecr.sh` usa `describe-repositories`, então `ecr:DescribeRepositories` está incluído.
