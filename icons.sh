#!/usr/bin/env bash
# Instala e aplica os ícones Slot-Dark-Icons (L4ki/Slot-Plasma-Themes) para o usuário.
# - Tema em ~/.local/share/icons/Slot-Dark-Icons (commit fixo, sem sudo).
# - GTK e Qt (QT_QPA_PLATFORMTHEME=gtk3, ex.: Dolphin) leem o gsettings.
# - O Omarchy reescreve o gsettings a cada troca de tema; o hook
#   theme-set.d/icon-theme reaplica depois.
# Idempotente: só baixa de novo se o commit mudar.
set -euo pipefail

theme=Slot-Dark-Icons
commit=ac0382d7bf096d4e061934691cd5f4543b02aac4
dest="$HOME/.local/share/icons/$theme"

if [[ $(cat "$dest/.commit" 2>/dev/null) != "$commit" ]]; then
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT
    git clone --quiet --filter=blob:none --no-checkout https://github.com/L4ki/Slot-Plasma-Themes "$tmp"
    git -C "$tmp" sparse-checkout set "Slot Icons Themes/$theme"
    git -C "$tmp" checkout --quiet "$commit"
    [[ -f "$tmp/Slot Icons Themes/$theme/index.theme" ]] || { echo "ERRO: index.theme não encontrado" >&2; exit 1; }
    rm -rf "$dest"
    mkdir -p "$(dirname "$dest")"
    cp -r "$tmp/Slot Icons Themes/$theme" "$dest"
    gtk-update-icon-cache -f -t "$dest" >/dev/null 2>&1 || true
    echo "$commit" >"$dest/.commit"
    echo "$theme instalado em $dest"
fi

gsettings set org.gnome.desktop.interface icon-theme "$theme"

# Flatpaks: enxergam o tema (~/.local/share/icons) e o kdeglobals (apps Qt/KDE como o ZapZap).
if command -v flatpak >/dev/null; then
    flatpak override --user --filesystem=xdg-data/icons:ro --filesystem=xdg-config/kdeglobals:ro
fi
