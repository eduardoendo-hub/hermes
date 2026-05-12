#!/usr/bin/env bash
# Hermes — sincroniza branding/ pra dentro do volume 'branding' do Coolify.
#
# Coolify cria volumes Docker nomeados (não bind mounts). Pra colocar arquivos
# lá, a forma mais simples é:
#   1) rsync branding/ pro host do Coolify (via SSH)
#   2) docker cp pra dentro do volume montado num container temporário
#
# Uso:
#   ./scripts/sync-branding.sh <coolify-server-ssh>
#
# Exemplo:
#   ./scripts/sync-branding.sh root@coolify.exemplo.com
#
# Pré-req: chave SSH carregada, acesso sudo (ou root) no host Coolify pra
# executar `docker cp`.

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Uso: $0 <coolify-server-ssh>" >&2
  echo "Ex.: $0 root@coolify.exemplo.com" >&2
  exit 1
fi

SSH_TARGET="$1"
REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
BRANDING_DIR="$REPO_ROOT/branding"
RESOURCE_NAME="${RESOURCE_NAME:-chatwoot}"

[[ -d "$BRANDING_DIR" ]] || { echo "branding/ não encontrado em $REPO_ROOT" >&2; exit 1; }

REMOTE_TMP="/tmp/hermes-branding-$(date +%s)"

echo "==> Copiando branding/ pra ${SSH_TARGET}:${REMOTE_TMP}"
rsync -avz "${BRANDING_DIR}/" "${SSH_TARGET}:${REMOTE_TMP}/"

echo "==> Descobrindo o volume 'branding' via Docker (procurando por *_branding ou *-branding)..."
VOLUME_NAME=$(ssh "$SSH_TARGET" "docker volume ls --format '{{.Name}}' | grep -i 'branding' | head -1") || true

if [[ -z "$VOLUME_NAME" ]]; then
  echo "Erro: nenhum volume contendo 'branding' encontrado." >&2
  echo "Liste com: ssh $SSH_TARGET 'docker volume ls'" >&2
  echo "Exporte VOLUME_NAME=<nome> e rode de novo." >&2
  exit 1
fi
echo "    Volume: $VOLUME_NAME"

echo "==> Copiando arquivos pra dentro do volume via container temporário..."
ssh "$SSH_TARGET" "
  docker run --rm \
    -v ${VOLUME_NAME}:/branding \
    -v ${REMOTE_TMP}:/src:ro \
    alpine:3 \
    sh -c 'cp -v /src/*.svg /src/*.css /branding/ && ls -la /branding/'
"

echo "==> Limpando staging area..."
ssh "$SSH_TARGET" "rm -rf ${REMOTE_TMP}"

echo
echo "================================================================"
echo "  Branding sincronizado em $VOLUME_NAME"
echo "  Próximo passo:"
echo "    1) Coolify UI → resource chatwoot → Restart (rails + sidekiq)"
echo "    2) Login no Chatwoot → Settings → Custom CSS → cole branding/custom.css"
echo "================================================================"
