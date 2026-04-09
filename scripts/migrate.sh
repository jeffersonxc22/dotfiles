#!/usr/bin/env bash
# migrate.sh — migra ~/.config/* para ~/dotfiles/<pacote>/.config/<pacote>
# e cria symlinks via stow

DOTFILES="$HOME/dotfiles"
CONFIG="$HOME/.config"

# Pacotes para ignorar (gerados por sistema, não faz sentido versionar)
IGNORE=(
  "google-chrome" "chromium" "BraveSoftware"
  "pulse" "pipewire"
  "dconf"
  "ibus"
  "systemd"
  "gtk-2.0" "gtk-3.0" "gtk-4.0"  # gerados automaticamente
  "plasma-workspace" "plasmashell" "plasma-org.kde.plasma.desktop-appletsrc"
  "kdeconnect"  # dados dinâmicos
  "session"
  "cache"
)

is_ignored() {
  local name="$1"
  for ig in "${IGNORE[@]}"; do
    [[ "$name" == "$ig" ]] && return 0
  done
  return 1
}

mkdir -p "$DOTFILES/scripts"

for item in "$CONFIG"/*/; do
  name=$(basename "$item")
  is_ignored "$name" && echo "⏭  ignorado: $name" && continue

  pkg_dir="$DOTFILES/$name/.config/$name"
  mkdir -p "$pkg_dir"

  # Move os arquivos (preserva estrutura interna)
  if [ -d "$item" ]; then
    cp -rn "$item"* "$pkg_dir/" 2>/dev/null
    echo "✓  migrado: $name"
  fi
done

echo ""
echo "Pronto. Agora rode: cd ~/dotfiles && stow *"
