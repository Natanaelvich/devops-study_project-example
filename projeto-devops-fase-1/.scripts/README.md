# Scripts – projeto-devops-fase-1

Execute a partir da raiz do projeto (`projeto-devops-fase-1/`).

## Variáveis de ambiente (.env)

As informações sensíveis ficam no arquivo **`.env`** na raiz do projeto (não versionado).

```bash
cp .env.example .env
# Edite .env com o caminho da chave PEM, IP da EC2, etc.
```

Variáveis usadas: `EC2_KEY_PATH`, `EC2_DEFAULT_HOST`, `EC2_SSH_USER`; opcionalmente `ECR_REPOSITORY_NAME`, `AWS_REGION`.

## push-ecr.sh

Envia a imagem `projeto-devops-fase-1-web:latest` para o repositório ECR `site_prod`.

```bash
./.scripts/push-ecr.sh           # região padrão: us-east-1
./.scripts/push-ecr.sh us-east-1
```

## connect-ec2.sh

Conecta via SSH à EC2 **web-server** (Amazon Linux 2). Caminho da chave e host vêm do **.env**.

```bash
./.scripts/connect-ec2.sh              # usa EC2_DEFAULT_HOST do .env
./.scripts/connect-ec2.sh <IP_ou_DNS>
```

**Variáveis no .env:** `EC2_KEY_PATH`, `EC2_DEFAULT_HOST`, `EC2_SSH_USER`
