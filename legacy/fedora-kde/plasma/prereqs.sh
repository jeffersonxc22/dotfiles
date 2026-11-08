#!/usr/bin/env bash
# Instala os pré-requisitos do perfil Plasma (plasma/README.md):
#   - Krohnkite 0.9.10.0 e Geometry Change v1.5 (versões do README)
#   - Layan KDE + Kvantum (upstream) e as personalizações de plasma/appearance
# Só instala; a aparência é aplicada por plasma/theme.sh.
#
# Uso: ./plasma/prereqs.sh   (dentro da sessão Plasma)
#
# Arquivos existentes substituídos vão para ~/.local/state/dotfiles/.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../bootstrap/lib.sh
source "$repo/bootstrap/lib.sh"
require_cmd git curl python3 kpackagetool6

backup="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/plasma-prereqs-$(date +%Y%m%d%H%M%S)"
mkdir -p "$backup"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

# release_asset <url-api> <sufixo> -> URL do primeiro asset com o sufixo
release_asset() {
    curl -fsSL "$1" | python3 -c '
import json, sys
suffix = sys.argv[1]
for a in json.load(sys.stdin).get("assets", []):
    if a["name"].endswith(suffix):
        print(a["browser_download_url"]); break
else:
    sys.exit("asset *" + suffix + " não encontrado")' "$2"
}

# kpkg_install <tipo> <arquivo>
kpkg_install() {
    kpackagetool6 --type "$1" --install "$2" 2>/dev/null || kpackagetool6 --type "$1" --upgrade "$2"
}

echo "== Krohnkite 0.9.10.0"
if [[ -f $HOME/.local/share/kwin/scripts/krohnkite/metadata.json ]]; then
    echo "  já instalado"
else
    url="$(release_asset https://codeberg.org/api/v1/repos/anametologin/Krohnkite/releases/tags/0.9.10.0 .kwinscript)"
    curl -fsSL "$url" -o "$tmp/krohnkite.kwinscript"
    kpkg_install KWin/Script "$tmp/krohnkite.kwinscript"
fi

echo "== Geometry Change v1.5"
if [[ -f $HOME/.local/share/kwin/effects/kwin4_effect_geometry_change/metadata.json ]]; then
    echo "  já instalado"
else
    url="$(release_asset https://api.github.com/repos/peterfajdiga/kwin4_effect_geometry_change/releases/tags/v1.5 .tar.gz)"
    curl -fsSL "$url" -o "$tmp/geometry_change.tar.gz"
    kpkg_install KWin/Effect "$tmp/geometry_change.tar.gz"
fi

echo "== Layan (upstream)"
# O Layan-kde já traz o Kvantum (instala em ~/.config/Kvantum/Layan).
layan_kde="$(fetch_repo https://github.com/vinceliuice/Layan-kde HEAD Layan-kde)"
(cd "$layan_kde" && ./install.sh)

echo "== Personalizações Layan dos dotfiles"
place() { # place <origem> <destino>
    if [[ -e $2 ]]; then mkdir -p "$backup/$(dirname "${2#$HOME/}")"; cp -a "$2" "$backup/${2#$HOME/}"; rm -rf "$2"; fi
    mkdir -p "$(dirname "$2")"; cp -a "$1" "$2"
}
app="$repo/plasma/appearance"
place "$app/LayanDark.kvconfig"    "$HOME/.config/Kvantum/Layan/LayanDark.kvconfig"
place "$app/aurorae-Layan"         "$HOME/.local/share/aurorae/themes/Layan"

echo
echo "Pré-requisitos instalados. Backup (se houve substituição): $backup"
