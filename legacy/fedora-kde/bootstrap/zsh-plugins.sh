#!/usr/bin/env bash
# Prepara ~/.local/share/zsh/plugins, onde o .zshrc procura os plugins:
#   - zsh-autosuggestions e zsh-syntax-highlighting vêm do dnf
#     (packages.txt) e recebem um link para /usr/share/<nome>;
#   - fzf-tab e zsh-completions são clonados em commits pinados.
#
# Uso: ./bootstrap/zsh-plugins.sh
set -euo pipefail

DEST="${ZSH_PLUGIN_DIR:-$HOME/.local/share/zsh/plugins}"

# nome|url|commit
PLUGINS=(
    "fzf-tab|https://github.com/Aloxaf/fzf-tab|24105b15714bfec37989ed5c5b6e60f572253019"
    "zsh-completions|https://github.com/zsh-users/zsh-completions|989b23277ab33e8d5e82df6aed936e846db9d8b8"
)

mkdir -p "$DEST"

for name in zsh-autosuggestions zsh-syntax-highlighting; do
    if [[ ! -e $DEST/$name && -r /usr/share/$name/$name.zsh ]]; then
        ln -s "/usr/share/$name" "$DEST/$name"
        echo "  $DEST/$name -> /usr/share/$name"
    fi
done

for entry in "${PLUGINS[@]}"; do
    IFS='|' read -r name url commit <<<"$entry"
    dir="$DEST/$name"

    if [[ ! -d $dir/.git ]]; then
        echo "→ clonando $name"
        if [[ -e $dir ]]; then
            echo "ERRO: destino existente não é um clone Git: $dir" >&2
            exit 1
        fi
        git clone --quiet "$url" "$dir"
    else
        if [[ -n $(git -C "$dir" status --porcelain) ]]; then
            echo "ERRO: plugin com alterações locais: $dir" >&2
            exit 1
        fi
        echo "→ atualizando $name"
        git -C "$dir" fetch --quiet --tags origin
    fi

    if ! git -C "$dir" checkout --quiet "$commit"; then
        echo "ERRO: commit $commit não encontrado em $name" >&2
        exit 1
    fi

    echo "  $name em $commit"
done
