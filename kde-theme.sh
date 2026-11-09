#!/usr/bin/env bash
# Aparência e integração dos apps KDE (Dolphin) no Omarchy: Kvantum LayanDark com paleta
# Catppuccin Mocha, esquema CatppuccinMochaSapphire e ícones Slot-Dark-Icons.
# Fora do Plasma, os apps KDE leem estilo, cores e ícones do ~/.config/kdeglobals
# (sem ele, caem no Breeze). Os arquivos vêm de legacy/fedora-kde/plasma/appearance.
# Pré-requisitos: kvantum instalado e ./icons.sh já rodado. Idempotente.
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
app="$repo/legacy/fedora-kde/plasma/appearance"
scheme=CatppuccinMochaSapphire

install -Dm644 "$app/LayanDark.kvconfig" "$HOME/.config/Kvantum/LayanDark/LayanDark.kvconfig"
install -Dm644 "$app/LayanDark.svg" "$HOME/.config/Kvantum/LayanDark/LayanDark.svg"
kwriteconfig6 --file "$HOME/.config/Kvantum/kvantum.kvconfig" --group General --key theme LayanDark
# Translúcido como o Layan original: só o fundo fica transparente (texto nítido)
# e o Hyprland desfoca o que está atrás. No Fedora era opaco.
kv="$HOME/.config/Kvantum/LayanDark/LayanDark.kvconfig"
kwriteconfig6 --file "$kv" --group %General --key translucent_windows true
kwriteconfig6 --file "$kv" --group %General --key reduce_window_opacity 20
kwriteconfig6 --file "$kv" --group %General --key reduce_menu_opacity 15
kwriteconfig6 --file "$kv" --group %General --key opaque_colors false

install -Dm644 "$app/$scheme.colors" "$HOME/.local/share/color-schemes/$scheme.colors"
# Copia os grupos de cor do esquema para o kdeglobals (o que o plasma-apply-colorscheme faria).
python3 -I - "$app/$scheme.colors" "$HOME/.config/kdeglobals" <<'PY'
import configparser, sys
src, dst = sys.argv[1], sys.argv[2]
scheme, out = configparser.ConfigParser(interpolation=None), configparser.ConfigParser(interpolation=None)
scheme.optionxform = out.optionxform = str
scheme.read(src); out.read(dst)
for sec in scheme.sections():
    if sec.startswith("Colors:") or sec in ("WM", "ColorEffects:Disabled", "ColorEffects:Inactive"):
        if not out.has_section(sec): out.add_section(sec)
        for k, v in scheme[sec].items(): out[sec][k] = v
with open(dst, "w") as f: out.write(f, space_around_delimiters=False)
PY
kwriteconfig6 --file kdeglobals --group General --key ColorScheme "$scheme"
kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle kvantum
kwriteconfig6 --file kdeglobals --group Icons --key Theme Slot-Dark-Icons
# Terminal do Dolphin (Alt+Shift+F4): fora do Plasma o padrão é o Konsole (não instalado).
# Só TerminalApplication: com TerminalService o Dolphin tira o ícone do item do
# .desktop do kitty e o menu fica sem ícone; sem ele, usa utilities-terminal.
kwriteconfig6 --file kdeglobals --group General --key TerminalApplication kitty
kwriteconfig6 --file kdeglobals --group General --key TerminalService --delete
# No menu de contexto o item do Dolphin sai: o pacote stow "dolphin" põe o
# "Abrir Claude Code no terminal" junto dos menus do Claude Desktop (o bloco de ações
# fica com até 4 itens) e o "Abrir terminal (kitty)" no fim do menu.
kwriteconfig6 --file dolphinrc --group ContextMenu --key ShowOpenTerminal false
echo "Aparência KDE aplicada. Reabra o Dolphin."
