#!/usr/bin/env bash
# Instala a família Geist para todo o sistema: Geist (interface) e GeistMono Nerd Font
# (terminal e monospace). O Fedora não tem rpm delas; vêm dos releases oficiais
# (vercel/geist-font e ryanoasis/nerd-fonts), em versão fixa e com sha256 conferido.
# Ficam em /usr/share/fonts, e não na home, porque a tela de login também as usa.
#
# Uso: ./bootstrap/fonts.sh   (pede sudo; idempotente: só baixa se a versão mudar)
set -euo pipefail

# install_font <pasta> <versão> <url> <sha256> <padrão dos arquivos dentro do pacote>
install_font() {
    local dest="/usr/share/fonts/$1" version="$2" url="$3" sha="$4" pattern="$5" tmp
    [[ $(cat "$dest/.version" 2>/dev/null) == "$version" ]] && { echo "  $1 $version já instalada"; return 0; }
    tmp="$(mktemp -d)"
    curl -fsSL -o "$tmp/pkg" "$url"
    echo "$sha  $tmp/pkg" | sha256sum -c --quiet
    mkdir "$tmp/x"
    case "$url" in
        *.zip) unzip -q "$tmp/pkg" -d "$tmp/x" ;;
        *) tar -xf "$tmp/pkg" -C "$tmp/x" ;;
    esac
    sudo rm -rf "$dest"
    sudo mkdir -p "$dest"
    find "$tmp/x" -type f -path "$pattern" -exec sudo install -m644 -t "$dest" {} +
    [[ -n $(ls "$dest") ]] || { echo "ERRO: nenhum arquivo casou com $pattern" >&2; exit 1; }
    echo "$version" | sudo tee "$dest/.version" >/dev/null
    rm -rf "$tmp"
    echo "  $1 $version instalada em $dest"
}

install_font geist v1.9.2 \
    https://github.com/vercel/geist-font/releases/download/v1.9.2/geist-font-v1.9.2.zip \
    15f066d58dcb99fb10014a49913009fdaf41e464cfb8851a44b44e593c95d3d8 '*/Geist/otf/*.otf'
install_font geist-mono-nerd v3.5.1 \
    https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/GeistMono.tar.xz \
    d3ba4a7418cde16963fda0caa4f7ae866c509e0a864ec21e393455e1906e070c '*.otf'
sudo fc-cache -f >/dev/null
