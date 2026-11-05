#!/usr/bin/env bash
# Instala apenas links sem adotar ou substituir arquivos existentes.
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
command -v stow >/dev/null || { echo 'Instale GNU Stow primeiro.' >&2; exit 1; }
packages=(zsh nvim kitty starship git mise herdr fontconfig)
cd "$repo"
echo 'Verificando conflitos antes de criar links...'
stow --no-folding --simulate --verbose --target="$HOME" "${packages[@]}"
stow --no-folding --target="$HOME" "${packages[@]}"
