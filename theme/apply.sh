#!/usr/bin/env bash
# Aplica o tema Catppuccin no Plasma e propaga para GTK, kitty e Flatpak.
#
# Uso: ./theme/apply.sh [flavour] [accent]
#      padrão: mocha sapphire
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=common.sh
source "$repo/theme/common.sh"

flavour="$(normalize_flavour "${1:-mocha}")"
accent="$(normalize_accent "${2:-sapphire}")"
if [[ $accent != sapphire ]]; then
    echo 'ERRO: somente o accent sapphire é instalado por theme/catppuccin-kde.sh.' >&2
    exit 1
fi
scheme="$(scheme_name "$flavour" "$accent")"
lookandfeel="$(lookandfeel_name "$flavour" "$accent")"

require_kde_tools

for cmd in plasma-apply-lookandfeel kbuildsycoca6 kwriteconfig6; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "ERRO: '$cmd' não encontrado." >&2
        exit 1
    fi
done

if ! plasma-apply-lookandfeel -l 2>/dev/null | grep -Fxq "$lookandfeel"; then
    echo "ERRO: look-and-feel '$lookandfeel' não instalado." >&2
    echo "      Rode ./theme/catppuccin-kde.sh primeiro." >&2
    exit 1
fi

echo "→ look-and-feel: $lookandfeel"
plasma-apply-lookandfeel -a "$lookandfeel"

echo "→ esquema de cores: $scheme"
plasma-apply-colorscheme "$scheme"

# KWin: borda fina do tema Modern, sem o BorderSizeAuto do Plasma.
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key BorderSizeAuto false

# Fontes: interface em Inter, terminal/editor em Cascadia Mono NF.
ui_font="Inter,10,-1,5,50,0,0,0,0,0"
mono_font="Cascadia Mono NF,10,-1,5,50,0,0,0,0,0"
for key in font menuFont toolBarFont taskbarFont; do
    kwriteconfig6 --file kdeglobals --group General --key "$key" "$ui_font"
done
kwriteconfig6 --file kdeglobals --group General --key smallestReadableFont "Inter,8,-1,5,50,0,0,0,0,0"
kwriteconfig6 --file kdeglobals --group General --key fixed "$mono_font"
kwriteconfig6 --file kwinrc --group WM --key activeFont "$ui_font"

# Ícones.
if [[ -f /usr/share/icons/Papirus-Dark/index.theme ]]; then
    kwriteconfig6 --file kdeglobals --group Icons --key Theme "Papirus-Dark"
    "$repo/theme/papirus.sh" "$flavour" "$accent"
else
    echo "aviso: Papirus-Dark não instalado; mantendo o tema de ícones atual." >&2
fi

# Cursor.
if [[ -d /usr/share/icons/Future-cursors || -d $HOME/.local/share/icons/Future-cursors ]]; then
    plasma-apply-cursortheme Future-cursors --size 24
else
    echo "aviso: Future-cursors não instalado; rode ./theme/future-cursors.sh." >&2
fi

# GTK, kitty e Flatpak.
"$repo/theme/gtk.sh" "$flavour"
"$repo/theme/kitty-colors.sh"
"$repo/theme/flatpak.sh"

kbuildsycoca6 --noincremental >/dev/null 2>&1 || true

if command -v qdbus6 >/dev/null 2>&1; then
    qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
fi

# Ícones e decoração só aparecem em todo lugar depois de reiniciar o shell.
echo "→ reiniciando o plasmashell"
systemctl --user restart plasma-plasmashell.service >/dev/null 2>&1 || true

echo "Tema aplicado: $flavour / $accent."
