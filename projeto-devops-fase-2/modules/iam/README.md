# Módulo IAM

Este módulo cria uma IAM role e instance profile para permitir que instâncias EC2 acessem o ECR (Elastic Container Registry).

## Recursos Criados

- `aws_iam_role` - IAM role com permissão para EC2 assumir
- `aws_iam_role_policy_attachment` - Anexa política gerenciada `AmazonEC2ContainerRegistryReadOnly`
- `aws_iam_instance_profile` - Instance profile para anexar à instância EC2

## Uso

```hcl
module "iam" {
  source = "./modules/iam"

  role_name = "my-ecr-role"

  tags = {
    Environment = "dev"
    Project     = "my-project"
  }
}
```

## Variáveis

| Nome | Descrição | Tipo | Padrão | Obrigatório |
|------|-----------|------|--------|-------------|
| `role_name` | Nome da IAM role e instance profile | `string` | - | Sim |
| `tags` | Tags para aplicar aos recursos | `map(string)` | `{}` | Não |

## Outputs

| Nome | Descrição |
|------|-----------|
| `role_name` | Nome da IAM role |
| `role_arn` | ARN da IAM role |
| `instance_profile_name` | Nome do instance profile |
| `instance_profile_arn` | ARN do instance profile |

## Exemplo de Uso Completo

```hcl
module "iam" {
  source = "./modules/iam"

  role_name = "ecr-access-role"

  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# Usar o instance profile em uma instância EC2
resource "aws_instance" "example" {
  # ...
  iam_instance_profile = module.iam.instance_profile_name
}
```
