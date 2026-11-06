#!/usr/bin/env bash
# Ajusta GTK 3/4 para acompanhar o KDE: fonte Inter, Breeze-GTK, ícones
# Slot-Dark-Tray e cursor Catppuccin Mocha Sapphire. As cores continuam vindo do colors.css gerado pelo
# kde-gtk-config a partir do esquema Catppuccin.
#
# Uso: ./theme/gtk.sh [flavour]
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=common.sh
source "$repo/theme/common.sh"

flavour="$(normalize_flavour "${1:-mocha}")"
dark=true
[[ $flavour == latte ]] && dark=false

# Pede ao kded para regenerar colors.css a partir do kdeglobals atual.
if command -v busctl >/dev/null 2>&1; then
    busctl --user call org.kde.kded6 /kded org.kde.kded6 reconfigure >/dev/null 2>&1 || true
fi

for version in 3.0 4.0; do
    file="$HOME/.config/gtk-$version/settings.ini"
    mkdir -p "$(dirname "$file")"
    if [[ ! -f $file ]]; then
        printf '[Settings]\n' > "$file"
    fi

    set_gtk_key "$file" gtk-application-prefer-dark-theme "$dark"
    set_gtk_key "$file" gtk-theme-name "Breeze"
    set_gtk_key "$file" gtk-icon-theme-name "Slot-Dark-Tray"
    set_gtk_key "$file" gtk-font-name "Inter 10"
    set_gtk_key "$file" gtk-cursor-theme-name "catppuccin-mocha-sapphire-cursors"
    set_gtk_key "$file" gtk-cursor-theme-size "24"
    set_gtk_key "$file" gtk-decoration-layout "icon:minimize,maximize,close"
    echo "GTK $version: $file atualizado"
done
