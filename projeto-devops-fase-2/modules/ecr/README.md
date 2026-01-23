# Módulo ECR

Este módulo cria repositórios ECR (Elastic Container Registry) para armazenar imagens Docker.

## Recursos Criados

- `aws_ecr_repository` - Repositório ECR

## Uso

```hcl
module "ecr" {
  source = "./modules/ecr"

  repository_name = "my-app"

  tags = {
    Environment = "dev"
  }
}
```

## Variáveis

| Nome | Descrição | Tipo | Padrão | Obrigatório |
|------|-----------|------|--------|-------------|
| `repository_name` | Nome do repositório ECR | `string` | - | Sim |
| `image_tag_mutability` | Mutabilidade de tags de imagem | `string` | `"MUTABLE"` | Não |
| `scan_on_push` | Habilitar scan de imagens ao fazer push | `bool` | `false` | Não |
| `encryption_type` | Tipo de criptografia | `string` | `"AES256"` | Não |
| `tags` | Tags para aplicar aos recursos | `map(string)` | `{}` | Não |

## Outputs

| Nome | Descrição |
|------|-----------|
| `repository_url` | URL do repositório ECR |
| `repository_arn` | ARN do repositório ECR |
| `repository_name` | Nome do repositório ECR |

## Exemplo de Uso Completo

```hcl
module "ecr" {
  source = "./modules/ecr"

  repository_name     = "my-web-app"
  image_tag_mutability = "MUTABLE"
  scan_on_push        = true
  encryption_type     = "AES256"

  tags = {
    Environment = "production"
    Project     = "web-app"
  }
}

# Output para usar em scripts de build
output "ecr_url" {
  value = module.ecr.repository_url
}
```

## Notas

- **image_tag_mutability**: 
  - `MUTABLE` - Permite sobrescrever tags existentes
  - `IMMUTABLE` - Tags não podem ser sobrescritas (recomendado para produção)

- **scan_on_push**: 
  - Quando habilitado, as imagens são escaneadas automaticamente para vulnerabilidades
  - Pode aumentar o tempo de push

- **encryption_type**:
  - `AES256` - Criptografia padrão da AWS
  - `KMS` - Criptografia usando KMS (requer configuração adicional)
