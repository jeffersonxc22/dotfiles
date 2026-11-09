#!/usr/bin/env bash
# Família Geist em todo o sistema: Geist na interface e Geist Mono (Nerd) nos
# terminais e no apelido monospace, via `omarchy font set`.
# - GTK no host e Flatpaks GTK (via portal) e Qt com QT_QPA_PLATFORMTHEME=gtk3: gsettings.
# - Apps Qt/KDE em Flatpak (ex.: ZapZap): kdeglobals.
# - sans-serif no fontconfig: ~/.config/fontconfig/conf.d/50-ui-font.conf.
# - Barra e menus do Omarchy (quickshell): regra por prgname no mesmo arquivo.
# Pré-requisitos: ttf-geist e otf-geist-mono-nerd instalados. Idempotente.
set -euo pipefail

font=Geist
size=11
[[ -n $(fc-list "$font") ]] || { echo "ERRO: fonte $font não instalada (omarchy pkg aur add ttf-geist)" >&2; exit 1; }

# Arquivo real, não link do stow: o Flatpak monta ~/.config/fontconfig em
# ~/.var/app/<id>/config, onde um link relativo para os dotfiles quebra.
# O `omarchy font set` reescreve fonts.conf, não este arquivo.
mkdir -p "$HOME/.config/fontconfig/conf.d"
cat >"$HOME/.config/fontconfig/conf.d/50-ui-font.conf" <<XML
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <match target="pattern">
    <test name="family" qual="any"><string>sans-serif</string></test>
    <edit name="family" mode="prepend_first" binding="strong"><string>$font</string></edit>
  </match>
  <!-- Barra e painéis do Omarchy (quickshell) pedem "monospace"; só para eles vira Geist.
       assign_replace troca a lista inteira: tira todos os "monospace" para o fonts.conf
       do omarchy font set (carregado depois) não reinserir a mono na frente. A GeistMono Nerd
       Font fica de reserva para os ícones Nerd da barra. Terminais e o resto continuam com a fonte mono. -->
  <match target="pattern">
    <test name="prgname"><string>quickshell</string></test>
    <test name="family" qual="any"><string>monospace</string></test>
    <edit name="family" mode="assign_replace" binding="strong">
      <string>$font</string>
      <string>GeistMono Nerd Font</string>
    </edit>
  </match>
</fontconfig>
XML

omarchy font set "GeistMono Nerd Font" >/dev/null

gsettings set org.gnome.desktop.interface font-name "$font $size"
gsettings set org.gnome.desktop.interface document-font-name "$font $size"
gsettings set org.gnome.desktop.interface monospace-font-name "GeistMono Nerd Font $size"

for key in font menuFont toolBarFont; do
    kwriteconfig6 --file kdeglobals --group General --key "$key" "$font,$size,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
done
kwriteconfig6 --file kdeglobals --group General --key smallestReadableFont "$font,9,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
kwriteconfig6 --file kdeglobals --group General --key fixed "GeistMono Nerd Font,$size,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"

# Flatpaks já veem as fontes do sistema; aqui leem também os apelidos do fontconfig do usuário.
if command -v flatpak >/dev/null; then
    flatpak override --user --filesystem=xdg-config/fontconfig:ro
fi
