#!/usr/bin/env bash
# Faz os Flatpaks seguirem o tema do host: cores do KDE, GTK, ícones, fontes
# e cursor. É um override global do usuário.
#
# Uso:
#   ./theme/flatpak.sh           # aplica
#   ./theme/flatpak.sh --reset   # remove os overrides
set -euo pipefail

if ! command -v flatpak >/dev/null 2>&1; then
    echo "flatpak não encontrado; nada a fazer."
    exit 0
fi

if [[ ${1:-} == "--reset" ]]; then
    flatpak override --user --reset
    echo "Overrides de Flatpak removidos."
    exit 0
fi

flatpak override --user \
    --filesystem=xdg-config/gtk-3.0:ro \
    --filesystem=xdg-config/gtk-4.0:ro \
    --filesystem=xdg-config/kdeglobals:ro \
    --filesystem=xdg-config/kcminputrc:ro \
    --filesystem=xdg-data/color-schemes:ro \
    --filesystem=xdg-data/themes:ro \
    --filesystem=xdg-data/icons:ro \
    --env=GTK_THEME=Breeze-Dark \
    --env=ICON_THEME=Slot-Dark-Tray \
    --env=XCURSOR_THEME=catppuccin-mocha-sapphire-cursors \
    --env=XCURSOR_SIZE=24 \
    --env=XDG_DATA_DIRS=/app/share:/usr/share:/run/host/share

echo "Override global de Flatpak aplicado. Auditoria: flatpak override --user --show"
