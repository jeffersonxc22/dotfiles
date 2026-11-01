#!/usr/bin/env bash
# Instala e ativa as units de usuário que mantêm as cores do kitty em sincronia
# com ~/.config/kdeglobals.
#
# Uso: ./theme/install-watch.sh
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
unit_dir="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"

if ! command -v systemctl >/dev/null 2>&1; then
    echo "systemctl não encontrado; pulando o watcher do kitty." >&2
    exit 0
fi

mkdir -p "$unit_dir"

for name in kitty-colors.service kitty-colors.path; do
    sed "s|@REPO@|$repo|g" "$repo/theme/systemd/$name.in" >"$unit_dir/$name"
done

chmod +x "$repo/theme/kitty-colors.sh"
systemctl --user daemon-reload
systemctl --user enable --now kitty-colors.path
systemctl --user start kitty-colors.service

echo "Watcher instalado: kitty recarrega quando ~/.config/kdeglobals mudar."
