#!/usr/bin/env bash
# Cria os links do stow para o Omarchy, sem --adopt. Antes, faz backup dos arquivos
# reais (não links) que estão no caminho e os tira de lá.
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
command -v stow >/dev/null || { echo 'Instale o stow: omarchy pkg add stow' >&2; exit 1; }

common=(git starship mise zsh)
omarchy=(hypr kitty hooks audio xdg cursor dolphin)

backup="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/omarchy-$(date +%Y%m%d%H%M%S)"
move_conflicts() {
    local dir="$1"; shift
    local pkg rel target
    for pkg in "$@"; do
        while IFS= read -r -d '' rel; do
            rel="${rel#./}"
            target="$HOME/$rel"
            if [[ -e $target && ! -L $target ]]; then
                mkdir -p "$backup/$(dirname "$rel")"
                mv "$target" "$backup/$rel"
                echo "backup: ~/$rel -> $backup/$rel"
            fi
        done < <(cd "$repo/$dir/$pkg" && find . -type f ! -name .gitkeep -print0)
    done
}
move_conflicts common "${common[@]}"
move_conflicts omarchy "${omarchy[@]}"

stow_dir() {
    local dir="$1"; shift
    stow --no-folding --simulate --verbose --ignore='\.gitkeep' -d "$repo/$dir" -t "$HOME" "$@"
    stow --no-folding --ignore='\.gitkeep' -d "$repo/$dir" -t "$HOME" "$@"
}
stow_dir common "${common[@]}"
stow_dir omarchy "${omarchy[@]}"

# Pasta de fundos de cada tema -> ~/Recursos/Imagens/Wallpapers (temas novos: hook theme-set)
"$HOME/.config/omarchy/hooks/theme-set.d/link-wallpapers" --all

if command -v hyprctl >/dev/null && [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
    hyprctl reload >/dev/null
    errors=$(hyprctl configerrors)
    [[ -z ${errors//[[:space:]]/} ]] && echo 'Hyprland: sem erros' || { echo "$errors"; exit 1; }
fi
echo 'Pronto.'
