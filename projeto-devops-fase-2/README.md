# Laboratório DevOps - Fase 2: Infraestrutura como Código (Terraform)

Este projeto provisiona automaticamente a mesma infraestrutura que a [Fase 1](../projeto-devops-fase-1/) configura manualmente: ECR, EC2, Security Group e IAM, além de **deploy automático** do container na EC2 via `user_data` (Docker + pull da imagem ECR com retry).

## Pré-requisitos

- [Terraform](https://www.terraform.io/downloads) >= 1.x
- AWS CLI configurado (`aws configure`)
- VPC existente (use o ID da VPC default ou da sua VPC)
- Key Pair criada na AWS para acesso SSH à EC2

## Uso rápido

1. Copie e preencha as variáveis:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edite terraform.tfvars (vpc_id, key_pair_name, etc.)
   ```
2. Inicialize e aplique:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

Ver [ARCHITECTURE.md](ARCHITECTURE.md) e [VARIABLES.md](VARIABLES.md) para detalhes.

## Fluxo após `terraform apply`

Após o apply, a EC2 sobe com um script de bootstrap que instala Docker e fica tentando fazer pull da imagem no ECR a cada 2 minutos até a imagem existir. Para deixar o site no ar:

1. **Configurar `.env` na Fase 1** (na raiz de `projeto-devops-fase-1/`):
   - `ECR_REPOSITORY_NAME`: mesmo nome do repositório ECR do Terraform (ex.: `site_prod`, valor de `ecr_repository_name`).
   - `EC2_KEY_PATH`: caminho para o arquivo `.pem` da Key Pair usada na EC2.
   - `EC2_DEFAULT_HOST`: IP público da EC2 (use o output `instance_public_ip` do Terraform).
   Exemplo após o apply:
   ```bash
   cd ../projeto-devops-fase-1
   echo "ECR_REPOSITORY_NAME=site_prod" >> .env
   echo "EC2_KEY_PATH=/caminho/para/chave-site-prod.pem" >> .env
   echo "EC2_DEFAULT_HOST=$(cd ../projeto-devops-fase-2 && terraform output -raw instance_public_ip)" >> .env
   ```

2. **Build e push da imagem** (a partir da raiz de `projeto-devops-fase-1/`):
   ```bash
   ./.scripts/push-ecr.sh us-east-1
   ```
   Use a região configurada em `aws_region` no Terraform.

3. **Aguardar o bootstrap na EC2**: o `user_data` na EC2 faz retry do pull a cada 2 minutos. Após o push, em até ~2 minutos o container sobe sozinho.

4. **Acessar o site**: `http://<instance_public_ip>` (use `terraform output instance_public_ip`).

### Conectar na EC2 (opcional)

Na **Fase 2**, use o script local (chave em `projeto-devops-fase-2/`):
```bash
cd projeto-devops-fase-2
./.scripts/connect-ec2.sh
# ou: ./.scripts/connect-ec2.sh <IP>
```
Coloque `chave-site-prod.pem` na raiz de `projeto-devops-fase-2/`. O script usa o IP do `terraform output` quando disponível, ou um padrão.

Alternativa na Fase 1 (com `.env` configurado):
```bash
cd ../projeto-devops-fase-1
./.scripts/connect-ec2.sh
# ou: ./.scripts/connect-ec2.sh <instance_public_ip>
```

Se o container ainda não tiver subido (imagem ainda não existia no ECR), você pode rodar manualmente na EC2:
```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account>.dkr.ecr.us-east-1.amazonaws.com
docker pull <ecr_repository_url>:latest
docker run -d -p 80:80 --restart always --name site-prod <ecr_repository_url>:latest
```
Use `terraform output ecr_repository_url` para obter a URL do repositório.

## Outputs úteis

| Output | Uso |
|--------|-----|
| `instance_public_ip` | IP para acessar o site e para `EC2_DEFAULT_HOST` no `.env` |
| `ecr_repository_url` | URL do repositório ECR (push e pull) |
| `instance_public_dns` | DNS público da EC2 |

## Documentação adicional

- [ARCHITECTURE.md](ARCHITECTURE.md) – Estrutura e módulos
- [VARIABLES.md](VARIABLES.md) – Variáveis e segurança
- [.docs/](.docs/) – Comandos, boas práticas e troubleshooting
