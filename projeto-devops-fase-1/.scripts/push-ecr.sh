#!/usr/bin/env bash
# Push da imagem projeto-devops-fase-1-web:latest para AWS ECR (repositório site_prod)
# Uso: .scripts/push-ecr.sh [região]
# Ex.: .scripts/push-ecr.sh us-east-1

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"
if [[ -f "$PROJECT_ROOT/.env" ]]; then
  set -a
  # shellcheck source=/dev/null
  source "$PROJECT_ROOT/.env"
  set +a
fi

IMAGE_NAME="projeto-devops-fase-1-web"
IMAGE_TAG="latest"
ECR_REPO_NAME="${ECR_REPOSITORY_NAME:-site_prod}"
REGION="${1:-${AWS_REGION:-us-east-1}}"

echo "=== Push para AWS ECR ==="
echo "Imagem: ${IMAGE_NAME}:${IMAGE_TAG}"
echo "Região: ${REGION}"
echo ""

# Obter Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null) || {
  echo "Erro: AWS CLI não configurado ou sem permissão. Execute 'aws configure'."
  exit 1
}

ECR_URI="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${ECR_REPO_NAME}"

# Verificar se o repositório ECR existe
if ! aws ecr describe-repositories --repository-names "${ECR_REPO_NAME}" --region "${REGION}" &>/dev/null; then
  echo "Erro: Repositório ECR '${ECR_REPO_NAME}' não encontrado. Crie-o no console AWS ou via Terraform."
  exit 1
fi
echo "Repositório ECR: ${ECR_REPO_NAME}"

# Build para linux/amd64 (EC2 usa x86_64 - evita "exec format error" em Mac ARM)
echo "Construindo imagem para linux/amd64 (EC2)..."
docker build --platform linux/amd64 -t "${IMAGE_NAME}:${IMAGE_TAG}" -f Dockerfile .

# Login no ECR
echo "Autenticando no ECR..."
aws ecr get-login-password --region "${REGION}" | \
  docker login --username AWS --password-stdin "${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

# Tag da imagem para o ECR
echo "Marcando imagem para ${ECR_URI}:${IMAGE_TAG}"
docker tag "${IMAGE_NAME}:${IMAGE_TAG}" "${ECR_URI}:${IMAGE_TAG}"

# Push
echo "Enviando imagem..."
docker push "${ECR_URI}:${IMAGE_TAG}"

echo ""
echo "Push concluído: ${ECR_URI}:${IMAGE_TAG}"
