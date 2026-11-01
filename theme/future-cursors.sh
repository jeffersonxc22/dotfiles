#!/usr/bin/env bash
# Instala o tema de cursor Future-cursors em /usr/share/icons.
#
# Uso: ./theme/future-cursors.sh
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../bootstrap/lib.sh
source "$repo/bootstrap/lib.sh"

require_cmd git

commit="587c14d2f5bd2dc34095a4efbb1a729eb72a1d36"
src="$(fetch_repo https://github.com/yeyushengfan258/Future-cursors "$commit" Future-cursors)"

if [[ ! -f $src/dist/index.theme ]]; then
    echo "ERRO: dist/index.theme não encontrado no Future-cursors." >&2
    exit 1
fi

sudo install -d /usr/share/icons
if [[ -e /usr/share/icons/Future-cursors ]]; then
    echo "ERRO: /usr/share/icons/Future-cursors já existe; não será sobrescrito." >&2
    exit 1
fi
sudo cp -pr "$src/dist" /usr/share/icons/Future-cursors

echo "Future-cursors instalado em /usr/share/icons/Future-cursors."
