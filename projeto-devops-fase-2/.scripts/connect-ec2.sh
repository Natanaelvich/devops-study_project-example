#!/usr/bin/env bash
# Conecta via SSH à EC2 do projeto (dev-website-server, Amazon Linux 2)
# Uso: .scripts/connect-ec2.sh [IP_ou_DNS]
# Chave: chave-site-prod.pem na raiz do projeto (projeto-devops-fase-2)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
KEY_NAME="chave-site-prod"
KEY_PATH="${PROJECT_ROOT}/${KEY_NAME}.pem"
SSH_USER="ec2-user"

# Host: argumento, ou .env (EC2_DEFAULT_HOST), ou output do Terraform, ou padrão
if [[ -f "$PROJECT_ROOT/.env" ]]; then
  set -a
  # shellcheck source=/dev/null
  source "$PROJECT_ROOT/.env"
  set +a
fi

HOST="${1:-${EC2_DEFAULT_HOST:-}}"
if [[ -z "$HOST" ]]; then
  if command -v terraform &>/dev/null && [[ -f "$PROJECT_ROOT/main.tf" ]]; then
    HOST=$(cd "$PROJECT_ROOT" && terraform output -raw instance_public_ip 2>/dev/null) || true
  fi
fi
if [[ -z "$HOST" ]]; then
  HOST="98.81.83.25"
fi

if [[ ! -f "$KEY_PATH" ]]; then
  echo "Erro: Chave não encontrada em $KEY_PATH"
  echo "Coloque ${KEY_NAME}.pem na raiz do projeto: $PROJECT_ROOT"
  exit 1
fi

chmod 400 "$KEY_PATH" 2>/dev/null || true
exec ssh -i "$KEY_PATH" -o StrictHostKeyChecking=accept-new "${SSH_USER}@${HOST}"
