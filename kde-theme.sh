#!/usr/bin/env bash
# Aparência dos apps KDE (Dolphin) no Omarchy: Kvantum LayanDark com paleta
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
echo "Aparência KDE aplicada. Reabra o Dolphin."
