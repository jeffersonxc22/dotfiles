#!/usr/bin/env bash
# Instala o que os dotfiles precisam no Omarchy e aplica os links.
# Rode num terminal: o sudo pode pedir a senha.
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

omarchy pkg add stow omarchy-zsh zsh-autosuggestions ttf-cascadia-mono-nerd inter-font
command -v kitty >/dev/null || omarchy install terminal kitty
omarchy default terminal kitty
# Dolphin como gerenciador de arquivos, com tema Kvantum.
omarchy pkg add dolphin kio-extras archlinux-xdg-menu kvantum

# zsh do jeito do Omarchy: o ~/.bashrc passa a fazer `exec zsh` (sem chsh).
# Só roda uma vez: depois, ~/.zshrc é link para os dotfiles, e o cp do setup
# escreveria por cima do arquivo do repositório.
if ! grep -q 'exec zsh' "$HOME/.bashrc" 2>/dev/null; then
    omarchy-setup-zsh
fi

"$repo/deploy.sh"

# Cursor Future-cursors: tema, gsettings (GTK/Flatpak) e sessão atual.
"$repo/cursor.sh"

# Ícones Slot-Dark-Icons em todo o sistema (GTK, Qt, shell e Flatpak).
"$repo/icons.sh"

# Dolphin: LayanDark com paleta Catppuccin, padrão para pastas e cache do "Abrir com".
"$repo/kde-theme.sh"
xdg-mime default org.kde.dolphin.desktop inode/directory
XDG_MENU_PREFIX=arch- kbuildsycoca6 --noincremental >/dev/null 2>&1 || true

echo
echo 'Feito. Faça logout/login para o cursor valer em toda a sessão.'
echo 'Abra um terminal novo para entrar no zsh.'
