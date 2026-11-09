#!/usr/bin/env bash
# Instala e aplica o cursor Future-cursors (yeyushengfan258) para o usuário.
# - Tema em ~/.local/share/icons/Future-cursors (commit fixo, sem sudo).
# - Hyprland: XCURSOR_THEME no looknfeel.lua; aqui só aplica na sessão atual.
# - GTK/libadwaita e Flatpak: gsettings (o Flatpak lê ~/.local/share/icons).
# - X11/XWayland e apps sem configuração: ~/.local/share/icons/default (pacote stow "cursor").
# Idempotente: só baixa de novo se o commit mudar.
set -euo pipefail

theme=Future-cursors
size=24
commit=587c14d2f5bd2dc34095a4efbb1a729eb72a1d36
dest="$HOME/.local/share/icons/$theme"

if [[ $(cat "$dest/.commit" 2>/dev/null) != "$commit" ]]; then
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT
    curl -fsSL "https://codeload.github.com/yeyushengfan258/$theme/tar.gz/$commit" |
        tar -xz -C "$tmp" --strip-components=1
    [[ -f $tmp/dist/index.theme ]] || { echo "ERRO: dist/index.theme não encontrado" >&2; exit 1; }
    rm -rf "$dest"
    mkdir -p "$(dirname "$dest")"
    cp -r "$tmp/dist" "$dest"
    echo "$commit" >"$dest/.commit"
    echo "$theme instalado em $dest"
fi

gsettings set org.gnome.desktop.interface cursor-theme "$theme"
gsettings set org.gnome.desktop.interface cursor-size "$size"

if command -v hyprctl >/dev/null && [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
    hyprctl setcursor "$theme" "$size" >/dev/null
fi
