#!/usr/bin/env bash
# Leva o visual da sessão (esquema Catppuccin Mocha Sapphire, fontes, ícones
# e cursor) para a tela de login do SDDM com o tema Breeze — o mesmo que o
# botão "Aplicar configurações do Plasma" do KDE faz.
#
# Uso: sudo bash bootstrap/pikaos/sddm-sync.sh   (depois do theme-layan-catppuccin.sh)
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "Rode com sudo." >&2; exit 1; }
user="${SUDO_USER:?rode via sudo a partir do seu usuário}"
home="$(getent passwd "$user" | cut -d: -f6)"
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
scheme=CatppuccinMochaSapphire
cursor=catppuccin-mocha-sapphire-cursors
sddm_home="$(getent passwd sddm | cut -d: -f6)"
sddm_home="${sddm_home:-/var/lib/sddm}"
conf=/etc/sddm.conf.d/kde_settings.conf
kw() { command -v kwriteconfig6 >/dev/null && kwriteconfig6 "$@"; }

backup="/var/backups/dotfiles-sddm-$(date +%Y%m%d%H%M%S)"
mkdir -p "$backup"
for f in "$conf" "$sddm_home/.config/kdeglobals" "$sddm_home/.config/kcminputrc"; do
    [[ -e $f ]] && cp -a "$f" "$backup/" || true
done
echo "Backup: $backup"

# O greeter não lê o HOME do usuário: esquema, ícones e cursor vão para /usr/share.
install -Dm644 "$repo/plasma/appearance/$scheme.colors" "/usr/share/color-schemes/$scheme.colors"
for theme in "$cursor" Slot-Dark-Icons; do
    if [[ -d $home/.local/share/icons/$theme && ! -e /usr/share/icons/$theme ]]; then
        cp -a "$home/.local/share/icons/$theme" /usr/share/icons/
    fi
done

install -d -m 755 -o sddm -g sddm "$sddm_home/.config"
install -m 644 -o sddm -g sddm "$home/.config/kdeglobals" "$sddm_home/.config/kdeglobals"
icons=Slot-Dark-Icons; [[ -d /usr/share/icons/$icons ]] || icons=breeze-dark
kw --file "$sddm_home/.config/kdeglobals" --group Icons --key Theme "$icons"
kw --file "$sddm_home/.config/kdeglobals" --group KDE --key widgetStyle Breeze
printf '[Mouse]\ncursorTheme=%s\ncursorSize=24\n' "$cursor" > "$sddm_home/.config/kcminputrc"
chown sddm:sddm "$sddm_home/.config/kcminputrc"

kw --file "$conf" --group Theme --key CursorTheme "$cursor"
kw --file "$conf" --group Theme --key CursorSize 24
kw --file "$conf" --group Theme --key Font "Inter,10,-1,5,50,0,0,0,0,0"

echo "SDDM sincronizado (vale no próximo login). Para desfazer, copie de volta os arquivos de $backup."
