#!/usr/bin/env bash
# Clona/atualiza os plugins do zsh listados em zsh/.config/zsh/plugins.txt.
#
# Não precisa de sudo: tudo vai para ~/.local/share/zsh/plugins (dados locais
# da máquina), então não entra no repositório nem no stow.
#
# Uso: ./install/install-zsh-plugins.sh
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGINS_FILE="$REPO_DIR/zsh/.config/zsh/plugins.txt"
DEST="${ZSH_PLUGIN_DIR:-$HOME/.local/share/zsh/plugins}"

if [[ ! -f $PLUGINS_FILE ]]; then
    echo "ERRO: lista de plugins não encontrada em $PLUGINS_FILE" >&2
    exit 1
fi

mkdir -p "$DEST"

while read -r name url _; do
    # Ignora linhas vazias e comentários
    [[ -z ${name-} || $name == \#* ]] && continue

    if [[ -d $DEST/$name/.git ]]; then
        echo "→ atualizando $name"
        if ! git -C "$DEST/$name" pull --ff-only --quiet; then
            echo "  aviso: não foi possível atualizar $name (ficou na versão atual)" >&2
        fi
    else
        echo "→ clonando $name"
        git clone --depth 1 --quiet "$url" "$DEST/$name"
    fi
done < "$PLUGINS_FILE"

echo
echo "Plugins instalados em: $DEST"

if ! command -v zsh >/dev/null 2>&1; then
    echo
    echo "O zsh ainda não está instalado. Rode:"
    echo "  sudo apt install zsh bat"
fi
