#!/usr/bin/env bash
# Conecta via SSH à EC2 web-server (Amazon Linux 2)
# Uso: .scripts/connect-ec2.sh [IP_ou_DNS]
# Variáveis sensíveis: use o arquivo .env na raiz do projeto (veja .env.example).

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
if [[ -f "$PROJECT_ROOT/.env" ]]; then
  set -a
  # shellcheck source=/dev/null
  source "$PROJECT_ROOT/.env"
  set +a
fi

KEY_PATH="${EC2_KEY_PATH:?Defina EC2_KEY_PATH no .env}"
SSH_USER="${EC2_SSH_USER:-ec2-user}"
DEFAULT_HOST="${EC2_DEFAULT_HOST:-}"

HOST="${1:-$DEFAULT_HOST}"
if [[ -z "$HOST" ]]; then
  echo "Uso: $0 <IP_ou_DNS>   ou defina EC2_DEFAULT_HOST no .env"
  exit 1
fi

if [[ ! -f "$KEY_PATH" ]]; then
  echo "Erro: Chave não encontrada em $KEY_PATH"
  exit 1
fi

# SSH exige permissão restrita na chave
chmod 400 "$KEY_PATH" 2>/dev/null || true

exec ssh -i "$KEY_PATH" -o StrictHostKeyChecking=accept-new "${SSH_USER}@${HOST}"
