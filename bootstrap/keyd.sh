#!/usr/bin/env bash
# keyd (remapeamento dos teclados Logitech, ver keyd/README.md) pela forma
# oficial do projeto: compilar a tag fixa e `make install` (sem rpm no
# Fedora). Depois liga keyd/logitech.conf em /etc/keyd via stow e ativa o serviço.
#
# Uso: ./bootstrap/keyd.sh   (idempotente; pede sudo)
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$repo/bootstrap/lib.sh"
require_cmd git make gcc stow
tag=v2.6.0

if [[ $(keyd --version 2>/dev/null) != *"${tag#v}"* ]]; then
    src="$(fetch_repo https://github.com/rvaiya/keyd "$tag" keyd)"
    make -C "$src"
    sudo make -C "$src" install # /usr/local/bin/keyd e /usr/local/lib/systemd/system/keyd.service
fi

cd "$repo"
sudo stow --no-folding --simulate --target=/etc keyd
sudo stow --no-folding --target=/etc keyd
sudo keyd check /etc/keyd/logitech.conf
sudo systemctl daemon-reload
if systemctl is-active -q keyd; then sudo keyd reload; else sudo systemctl enable --now keyd; fi
echo "keyd $tag ativo (emergência: Backspace + Esc + Enter)."
