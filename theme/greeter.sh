#!/usr/bin/env bash
# Leva o visual da sessão (esquema Catppuccin Mocha Sapphire, fontes, ícones
# e cursor) para a tela de login do Plasma Login Manager, padrão do Fedora KDE.
# O greeter lê o HOME próprio (/var/lib/plasmalogin), não o do usuário.
#
# Uso: sudo ./theme/greeter.sh   (depois de ./plasma/theme.sh)
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "Rode com sudo." >&2; exit 1; }
user="${SUDO_USER:?rode via sudo a partir do seu usuário}"
home="$(getent passwd "$user" | cut -d: -f6)"
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
scheme=CatppuccinMochaSapphire
cursor=catppuccin-mocha-sapphire-cursors
dm_home="$(getent passwd plasmalogin | cut -d: -f6)"
[[ -n $dm_home ]] || { echo "ERRO: usuário plasmalogin não existe (Plasma Login Manager instalado?)." >&2; exit 1; }
kw() { kwriteconfig6 "$@"; }

backup="/var/backups/dotfiles-greeter-$(date +%Y%m%d%H%M%S)"
mkdir -p "$backup"
for f in "$dm_home/.config/kdeglobals" "$dm_home/.config/kcminputrc"; do
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

install -d -m 700 -o plasmalogin -g plasmalogin "$dm_home/.config"
install -m 600 -o plasmalogin -g plasmalogin "$home/.config/kdeglobals" "$dm_home/.config/kdeglobals"
icons=Slot-Dark-Icons; [[ -d /usr/share/icons/$icons ]] || icons=breeze-dark
kw --file "$dm_home/.config/kdeglobals" --group Icons --key Theme "$icons"
kw --file "$dm_home/.config/kdeglobals" --group KDE --key widgetStyle Breeze
printf '[Mouse]\ncursorTheme=%s\ncursorSize=24\n' "$cursor" > "$dm_home/.config/kcminputrc"
chown plasmalogin:plasmalogin "$dm_home/.config/kcminputrc"; chmod 600 "$dm_home/.config/kcminputrc"
# Rótulos SELinux corretos para o greeter ler os arquivos.
command -v restorecon >/dev/null && restorecon -R "$dm_home/.config" >/dev/null 2>&1 || true

echo "Login sincronizado (vale no próximo login). Para desfazer, copie de volta os arquivos de $backup."
# shortcut: a chave de fundo do /etc/plasmalogin.conf não está documentada; automatizar após ler /usr/lib/plasmalogin/defaults.conf no Fedora.
echo "Fundo sólido do login: Configurações do Sistema > Tela de Login > papel de parede 'Cor sólida' #1e1e2e."
