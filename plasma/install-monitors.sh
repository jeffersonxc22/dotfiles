#!/usr/bin/env bash
# Instala e ativa a unit de usuário que aplica plasma/monitors.sh no login.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
unit_dir="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
mkdir -p "$unit_dir"

sed "s|@REPO@|$repo|g" "$repo/plasma/systemd/user/dotfiles-monitors.service.in" \
    > "$unit_dir/dotfiles-monitors.service"
chmod +x "$repo/plasma/monitors.sh"

systemctl --user daemon-reload
systemctl --user enable --now dotfiles-monitors.service
echo "Layout de monitores aplicado e ativado no login."
