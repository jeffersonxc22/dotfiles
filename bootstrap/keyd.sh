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
# Um link antigo de outra localização do repositório (por exemplo, depois de
# renomear ~/dotfiles para ~/.dotfiles) fica quebrado e o stow o trata como
# conflito. Remove só links órfãos; arquivos reais não são tocados.
keyd_link=/etc/keyd/logitech.conf
if [[ -L $keyd_link && ! -e $keyd_link ]]; then
    sudo rm -f "$keyd_link"
fi
sudo stow --no-folding --simulate --target=/etc keyd
sudo stow --no-folding --target=/etc keyd
sudo keyd check "$keyd_link"
sudo systemctl daemon-reload
if systemctl is-active -q keyd; then
    echo "Link do keyd aplicado. Rode: sudo keyd reload"
else
    echo "Link do keyd aplicado. Rode: sudo systemctl enable --now keyd"
fi
echo "keyd $tag configurado (emergência: Backspace + Esc + Enter)."
