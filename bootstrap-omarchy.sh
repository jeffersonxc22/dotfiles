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
# JOPDF no lugar do Papers como leitor de PDF.
omarchy pkg aur add jopdf
# Sem Nautilus e Papers (o seletor de arquivos é o portal GTK). pacman -R simples:
# o `omarchy pkg drop` usa -Rns, que levaria junto o xdg-user-dirs.
mapfile -t gnome_apps < <(pacman -Qq nautilus nautilus-python sushi papers 2>/dev/null || true)
if ((${#gnome_apps[@]})); then sudo pacman -R --noconfirm "${gnome_apps[@]}"; fi
# Família Geist: interface (AUR) e terminais/monospace (Nerd Font).
omarchy pkg add otf-geist-mono-nerd
omarchy pkg aur add ttf-geist

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

# Geist na interface (GTK, Qt, Flatpak, barra do Omarchy) e Geist Mono nos terminais.
"$repo/fonts.sh"

# Dolphin: LayanDark com paleta Catppuccin e cache do "Abrir com". Apps padrão: Dolphin (pastas) e JOPDF (PDF).
"$repo/kde-theme.sh"
xdg-mime default org.kde.dolphin.desktop inode/directory
xdg-mime default jopdf.desktop application/pdf
XDG_MENU_PREFIX=arch- kbuildsycoca6 --noincremental >/dev/null 2>&1 || true

echo
echo 'Feito. Faça logout/login para o cursor valer em toda a sessão.'
echo 'Abra um terminal novo para entrar no zsh.'
