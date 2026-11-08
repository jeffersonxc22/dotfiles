#!/usr/bin/env bash
# Funções compartilhadas pelos scripts de bootstrap e de tema.
#
# Tudo é idempotente: baixar de novo só atualiza o checkout para o commit
# pinado, sem depender de branch móvel.

set -euo pipefail

DOTFILES_SRC="${DOTFILES_SRC:-${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/src}"

# fetch_repo <url> <commit> <nome> [destino]
#
# Clona (ou reaproveita) o repositório em $DOTFILES_SRC/<nome> e faz checkout
# do commit exato. O destino é impresso na saída padrão.
fetch_repo() {
    local url="$1" commit="$2" name="$3"
    local dest="${4:-$DOTFILES_SRC/$name}"

    mkdir -p "$(dirname "$dest")"

    if [[ ! -d $dest/.git ]]; then
        if [[ -e $dest ]]; then
            echo "ERRO: destino existente não é um clone Git: $dest" >&2
            return 1
        fi
        echo "→ clonando $name" >&2
        git clone --quiet "$url" "$dest"
    else
        if [[ -n $(git -C "$dest" status --porcelain) ]]; then
            echo "ERRO: clone com alterações locais: $dest" >&2
            return 1
        fi
        echo "→ atualizando $name" >&2
        git -C "$dest" fetch --quiet --tags origin
    fi

    if ! git -C "$dest" checkout --quiet "$commit" 2>/dev/null; then
        echo "ERRO: commit $commit não encontrado em $name" >&2
        return 1
    fi

    printf '%s\n' "$dest"
}

# require_cmd <comando>...
require_cmd() {
    local cmd
    for cmd in "$@"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo "ERRO: comando '$cmd' não encontrado. Rode ./bootstrap/install.sh primeiro." >&2
            exit 1
        fi
    done
}
