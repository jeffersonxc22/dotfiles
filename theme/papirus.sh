#!/usr/bin/env bash
# Colore as pastas do Papirus-Dark com a variante Catppuccin do flavour/accent.
#
# Uso: ./theme/papirus.sh [flavour] [accent]
#      padrão: mocha sapphire
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../bootstrap/lib.sh
source "$repo/bootstrap/lib.sh"
# shellcheck source=common.sh
source "$repo/theme/common.sh"

flavour="$(normalize_flavour "${1:-mocha}")"
accent="$(normalize_accent "${2:-sapphire}")"

require_cmd git

if [[ ! -f /usr/share/icons/Papirus-Dark/index.theme ]]; then
    echo "ERRO: Papirus-Dark não está instalado (pacote papirus-icon-theme-dark)." >&2
    exit 1
fi

folders_commit="f83671d17ea67e335b34f8028a7e6d78bca735d7"
folders_src="$(fetch_repo https://github.com/catppuccin/papirus-folders "$folders_commit" papirus-folders)"

tool_commit="0f838ee5679229e3a3e97e3b333c222c9e9615b4"
tool_src="$(fetch_repo https://github.com/PapirusDevelopmentTeam/papirus-folders "$tool_commit" papirus-folders-tool)"

chmod +x "$tool_src/papirus-folders"

echo "→ copiando assets Catppuccin para /usr/share/icons/Papirus"
sudo cp -r "$folders_src/src/." /usr/share/icons/Papirus/

echo "→ aplicando pastas cat-$flavour-$accent no Papirus-Dark"
sudo "$tool_src/papirus-folders" -C "cat-$flavour-$accent" --theme Papirus-Dark
