#!/usr/bin/env bash
# Instala o que os dotfiles precisam no Omarchy e aplica os links.
# Rode num terminal: o sudo pode pedir a senha.
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

omarchy pkg add stow omarchy-zsh zsh-autosuggestions ttf-cascadia-mono-nerd inter-font
omarchy pkg aur add catppuccin-cursors-mocha
command -v kitty >/dev/null || omarchy install terminal kitty
omarchy default terminal kitty

# zsh do jeito do Omarchy: o ~/.bashrc passa a fazer `exec zsh` (sem chsh).
# Só roda uma vez: depois, ~/.zshrc é link para os dotfiles, e o cp do setup
# escreveria por cima do arquivo do repositório.
if ! grep -q 'exec zsh' "$HOME/.bashrc" 2>/dev/null; then
    omarchy-setup-zsh
fi

"$repo/deploy.sh"

# Cursor também para apps GTK.
gsettings set org.gnome.desktop.interface cursor-theme catppuccin-mocha-sapphire-cursors
gsettings set org.gnome.desktop.interface cursor-size 24

echo
echo 'Feito. Faça logout/login para o cursor valer em toda a sessão.'
echo 'Abra um terminal novo para entrar no zsh.'
