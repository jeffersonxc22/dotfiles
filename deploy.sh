#!/usr/bin/env bash
# Cria os links do stow para o $HOME, sem --adopt: os arquivos reais (não links)
# que estiverem no caminho vão antes para ~/.local/state/dotfiles/.
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
command -v stow >/dev/null || { echo 'Instale o GNU Stow primeiro.' >&2; exit 1; }
packages=(zsh git starship mise kitty nvim fontconfig dolphin)

backup="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/deploy-$(date +%Y%m%d%H%M%S)"
for pkg in "${packages[@]}"; do
    while IFS= read -r -d '' rel; do
        rel="${rel#./}"
        target="$HOME/$rel"
        if [[ -e $target && ! -L $target ]]; then
            mkdir -p "$backup/$(dirname "$rel")"
            mv "$target" "$backup/$rel"
            echo "backup: ~/$rel -> $backup/$rel"
        fi
    done < <(cd "$repo/$pkg" && find . -type f -print0)
done
stow --no-folding --simulate --verbose -d "$repo" -t "$HOME" "${packages[@]}"
stow --no-folding -d "$repo" -t "$HOME" "${packages[@]}"
echo 'Pronto.'
