#!/usr/bin/env bash
# Configura a tela de login do Plasma Login Manager (plasmalogin): fonte Inter,
# esquema Layan ou Catppuccin e Future-cursors.
#
# Uso: sudo ./theme/greeter.sh [flavour] [accent]
#      padrão: mocha sapphire
#      Layan: sudo ./theme/greeter.sh layan
#
# O PLM lê o HOME próprio (/var/lib/plasmalogin), por isso os arquivos ficam
# separados do kdeglobals do usuário. As mudanças valem no próximo login.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=common.sh
source "$repo/theme/common.sh"

if [[ $EUID -ne 0 ]]; then
    echo "ERRO: rode com sudo: sudo $0 $*" >&2
    exit 1
fi

requested="${1:-mocha}"
if [[ ${requested,,} == layan ]]; then
    scheme=Layan
else
    flavour="$(normalize_flavour "${1:-mocha}")"
    accent="$(normalize_accent "${2:-sapphire}")"
    scheme="$(scheme_name "$flavour" "$accent")"
fi

user_home="$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)"
scheme_file="/usr/share/color-schemes/$scheme.colors"
if [[ ! -f $scheme_file && -f $user_home/.local/share/color-schemes/$scheme.colors ]]; then
    scheme_file="$user_home/.local/share/color-schemes/$scheme.colors"
fi

if [[ ! -f $scheme_file ]]; then
    echo "ERRO: esquema $scheme não encontrado. Rode ./theme/install.sh antes." >&2
    exit 1
fi

# O greeter não consegue percorrer o HOME privado do usuário.
if [[ $scheme_file != /usr/share/color-schemes/* ]]; then
    install -Dm644 "$scheme_file" "/usr/share/color-schemes/$scheme.colors"
    scheme_file="/usr/share/color-schemes/$scheme.colors"
fi

install -d -m 700 -o plasmalogin -g plasmalogin /var/lib/plasmalogin/.config

backup_dir="/var/lib/plasmalogin/.config/dotfiles-backup-$(date +%Y%m%d%H%M%S)"
mkdir -m 700 "$backup_dir"
for file in kdeglobals kcminputrc; do
    if [[ -e /var/lib/plasmalogin/.config/$file ]]; then
        cp -a "/var/lib/plasmalogin/.config/$file" "$backup_dir/$file"
    fi
done
echo "Backup da configuração anterior: $backup_dir"

install -m 600 -o plasmalogin -g plasmalogin "$scheme_file" \
    /var/lib/plasmalogin/.config/kdeglobals

kwriteconfig6 --file /var/lib/plasmalogin/.config/kdeglobals --group General --key ColorScheme "$scheme"
kwriteconfig6 --file /var/lib/plasmalogin/.config/kdeglobals --group General --key font "Inter,10,-1,5,50,0,0,0,0,0"
kwriteconfig6 --file /var/lib/plasmalogin/.config/kdeglobals --group General --key fixed "Cascadia Mono NF,10,-1,5,50,0,0,0,0,0"
kwriteconfig6 --file /var/lib/plasmalogin/.config/kdeglobals --group General --key menuFont "Inter,10,-1,5,50,0,0,0,0,0"
kwriteconfig6 --file /var/lib/plasmalogin/.config/kdeglobals --group General --key toolBarFont "Inter,10,-1,5,50,0,0,0,0,0"
kwriteconfig6 --file /var/lib/plasmalogin/.config/kdeglobals --group General --key smallestReadableFont "Inter,8,-1,5,50,0,0,0,0,0"
kwriteconfig6 --file /var/lib/plasmalogin/.config/kdeglobals --group Icons --key Theme "Papirus-Dark"
kwriteconfig6 --file /var/lib/plasmalogin/.config/kdeglobals --group KDE --key widgetStyle "Breeze"

kwriteconfig6 --file /var/lib/plasmalogin/.config/kcminputrc --group Mouse --key cursorTheme "Future-cursors"
kwriteconfig6 --file /var/lib/plasmalogin/.config/kcminputrc --group Mouse --key cursorSize "24"

chown plasmalogin:plasmalogin \
    /var/lib/plasmalogin/.config/kdeglobals \
    /var/lib/plasmalogin/.config/kcminputrc
chmod 600 \
    /var/lib/plasmalogin/.config/kdeglobals \
    /var/lib/plasmalogin/.config/kcminputrc

if command -v restorecon >/dev/null 2>&1; then
    restorecon -R /var/lib/plasmalogin/.config >/dev/null 2>&1 || true
fi

echo "Greeter configurado com $scheme, Inter e Future-cursors (aplica no próximo login)."
