#!/usr/bin/env bash
# Instala o Catppuccin KDE (4 flavours, accent Sapphire, decoração Modern)
# em /usr/share, sem cursor (o cursor é o Future-cursors).
#
# Uso: ./theme/catppuccin-kde.sh
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../bootstrap/lib.sh
source "$repo/bootstrap/lib.sh"
# shellcheck source=common.sh
source "$repo/theme/common.sh"

require_cmd git tar kpackagetool6

# v0.4.0
commit="6606b5179cfc1e9ba5c3b6b70e15c468e2dddca2"
src="$(fetch_repo https://github.com/catppuccin/kde "$commit" catppuccin-kde)"
work="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-kde.XXXXXXXX")"
trap 'rm -rf "$work"' EXIT
cp -a "$src/." "$work/source/"
stage="$work/data"
mkdir -p "$stage" "$work/config" "$work/cache"

for index in 1 2 3 4; do
    flavour="${FLAVOURS[$((index - 1))]}"
    cap="$(capitalize_flavour "$flavour")"
    echo "→ instalando Catppuccin $cap / Sapphire / Modern"

    # -n: não instala cursor; 12: Sapphire; 1: Modern (mixed).
    # O instalador upstream usa caminhos relativos; os modos de construção
    # evitam aplicar o tema à sessão de root durante a instalação.
    (cd "$work/source" && XDG_DATA_HOME="$stage" XDG_CONFIG_HOME="$work/config" XDG_CACHE_HOME="$work/cache" ./install.sh -q -n "$index" 12 1 aurorae)
    (cd "$work/source" && XDG_DATA_HOME="$stage" XDG_CONFIG_HOME="$work/config" XDG_CACHE_HOME="$work/cache" ./install.sh -q -n "$index" 12 1 global)
    sudo install -d /usr/share/aurorae/themes /usr/share/plasma/look-and-feel
    sudo cp -r "$stage/aurorae/themes/Catppuccin${cap}-Modern" /usr/share/aurorae/themes/
    sudo cp -r "$stage/plasma/look-and-feel/Catppuccin-${cap}-Sapphire" /usr/share/plasma/look-and-feel/
    sudo install -Dm644 "$src/generated/color-schemes/Catppuccin${cap}Sapphire.colors" "/usr/share/color-schemes/Catppuccin${cap}Sapphire.colors"

    if [[ ! -f /usr/share/color-schemes/Catppuccin${cap}Sapphire.colors ]]; then
        echo "ERRO: o esquema Catppuccin${cap}Sapphire não foi instalado." >&2
        exit 1
    fi
done

echo "Catppuccin KDE instalado em /usr/share (4 flavours, Sapphire, Modern)."
