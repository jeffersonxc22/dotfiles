#!/usr/bin/env bash
# new-env.sh — gera uma entrada genérica no distrobox.ini (a partir do
# template versionado no dotfiles) e cria o ambiente.
#
# O distrobox.ini.template fica no dotfiles (genérico, versionado).
# O distrobox.ini REAL, gerado a partir dele, fica em ~/Envs/distrobox.ini
# — NÃO vai pro dotfiles, porque tem paths específicos desta máquina
# (ex: home=/home/jefferson/Envs/nemu) e não faz sentido sincronizar
# entre máquinas diferentes.
#
# Uso:
#   ./new-env.sh <nome-do-env> [imagem] [nvidia:true|false]
#
# Exemplo:
#   ./new-env.sh cometa
#   ./new-env.sh sem-gpu-env kode-d:latest false

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

NAME="${1:?Uso: new-env.sh <nome-do-env> [imagem] [nvidia:true|false]}"
IMAGE="${2:-kode-d:latest}"
NVIDIA="${3:-true}"
USER_NAME="$(whoami)"

TEMPLATE="${SCRIPT_DIR}/distrobox.ini.template"
ENVS_ROOT="${HOME}/Envs"
TARGET="${ENVS_ROOT}/distrobox.ini"   # gerado, local desta máquina — NÃO fica no dotfiles

log() { printf '\n\033[1;32m==> %s\033[0m\n' "$1"; }

if [ ! -f "$TEMPLATE" ]; then
    echo "Erro: template não encontrado em $TEMPLATE"
    exit 1
fi

mkdir -p "$ENVS_ROOT"

# Evita duplicar entrada se o nome já existir no distrobox.ini
if [ -f "$TARGET" ] && grep -q "^\[$NAME\]" "$TARGET"; then
    echo "Erro: já existe uma entrada '[$NAME]' em $TARGET"
    exit 1
fi

log "Buildando imagem base ($IMAGE), se necessário"
if ! podman image exists "$IMAGE"; then
    podman build -t "$IMAGE" -f "${SCRIPT_DIR}/Dockerfile" "${SCRIPT_DIR}"
fi

log "Gerando entrada '[$NAME]' a partir do template"
# Extrai apenas o bloco [{{NAME}}]...fim (ignora o cabeçalho de comentários
# do template) e substitui os placeholders
sed -n '/^\[{{NAME}}\]/,$p' "$TEMPLATE" \
    | sed \
        -e "s|{{NAME}}|$NAME|g" \
        -e "s|{{IMAGE}}|$IMAGE|g" \
        -e "s|{{USER}}|$USER_NAME|g" \
        -e "s|{{NVIDIA}}|$NVIDIA|g" \
    >> "$TARGET"

log "Criando home isolado em ~/Envs/$NAME"
mkdir -p "${HOME}/Envs/${NAME}"

log "Assemblando o ambiente '$NAME' via distrobox"
distrobox assemble create --file "$TARGET" --name "$NAME"

log "Rodando o bootstrap dentro do ambiente '$NAME'"
distrobox enter "$NAME" -- bash "/home/${USER_NAME}/dotfiles/env/bootstrap.sh"

log "Ambiente '$NAME' pronto. Entre com: distrobox enter $NAME"
