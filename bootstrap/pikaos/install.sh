#!/usr/bin/env bash
# Bootstrap dos dotfiles para PikaOS (base Debian), equivalente a
# bootstrap/install.sh do Fedora.
#
# Uso: ./bootstrap/pikaos/install.sh
#
# Roda como usuário normal (usa sudo só para o apt) e é idempotente.
# Não altera arquivos versionados nem configs do KDE.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

. /etc/os-release
if [[ " ${ID:-} ${ID_LIKE:-} " != *" debian "* && " ${ID:-} ${ID_LIKE:-} " != *" ubuntu "* && ${ID:-} != pika ]]; then
    echo "ERRO: este script é para PikaOS/Debian (ID=${ID:-?})." >&2
    exit 1
fi

echo "== Pacotes do sistema (apt)"
mapfile -t wanted < <(grep -vE '^[[:space:]]*(#|$)' "$repo/bootstrap/pikaos/packages.txt")
sudo apt-get update
available=() missing=()
for pkg in "${wanted[@]}"; do
    if apt-cache show "$pkg" >/dev/null 2>&1; then available+=("$pkg"); else missing+=("$pkg"); fi
done
sudo apt-get install -y "${available[@]}"
((${#missing[@]})) && echo "aviso: não encontrados no apt (instale à parte): ${missing[*]}" >&2

mkdir -p "$HOME/.local/bin" "$HOME/.local/share/zsh/plugins" "$HOME/.local/share/fonts"

echo "== Nomes de binário do Debian (batcat/fdfind)"
link_bin() { # link_bin <nome> <binário-debian>
    if ! command -v "$1" >/dev/null 2>&1 && command -v "$2" >/dev/null 2>&1; then
        ln -sfn "$(command -v "$2")" "$HOME/.local/bin/$1"
        echo "  ~/.local/bin/$1 -> $2"
    fi
}
link_bin bat batcat
link_bin fd fdfind

echo "== Plugins de zsh"
"$repo/bootstrap/zsh-plugins.sh"
# O .zshrc procura todos os plugins em ~/.local/share/zsh/plugins; os do apt
# ficam em /usr/share. Um link resolve sem mexer no .zshrc.
for name in zsh-autosuggestions zsh-syntax-highlighting; do
    dest="$HOME/.local/share/zsh/plugins/$name"
    if [[ ! -e $dest && -d /usr/share/$name ]]; then
        ln -s "/usr/share/$name" "$dest"
        echo "  $dest -> /usr/share/$name"
    fi
done

echo "== Fonte Cascadia Mono NF"
if fc-list | grep -qi 'Cascadia Mono NF'; then
    echo "  já instalada"
else
    url="$(curl -fsSL https://api.github.com/repos/microsoft/cascadia-code/releases/latest \
        | python3 -c 'import json,sys; print(next(a["browser_download_url"] for a in json.load(sys.stdin)["assets"] if a["name"].endswith(".zip")))')"
    tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
    curl -fsSL "$url" -o "$tmp/cascadia.zip"
    unzip -q "$tmp/cascadia.zip" -d "$tmp/c"
    find "$tmp/c" -iname 'CascadiaMonoNF*.ttf' -exec install -m644 {} "$HOME/.local/share/fonts/" \;
    fc-cache -f >/dev/null
    fc-list | grep -qi 'Cascadia Mono NF' && echo "  instalada em ~/.local/share/fonts" \
        || echo "aviso: Cascadia Mono NF não encontrada no zip; verifique manualmente." >&2
fi

echo "== Tema Catppuccin do bat (BAT_THEME do .zshrc)"
if command -v bat >/dev/null 2>&1; then
    themes="$(bat --config-dir)/themes"
    if [[ ! -f $themes/Catppuccin\ Mocha.tmTheme ]]; then
        mkdir -p "$themes"
        curl -fsSL -o "$themes/Catppuccin Mocha.tmTheme" \
            "https://raw.githubusercontent.com/catppuccin/bat/main/themes/Catppuccin%20Mocha.tmTheme"
        bat cache --build >/dev/null
    fi
fi

echo "== mise (sem pacote no Debian)"
if ! command -v mise >/dev/null 2>&1 && [[ ! -x $HOME/.local/bin/mise ]]; then
    curl -fsSL https://mise.run | sh
fi

if ! command -v google-chrome >/dev/null 2>&1 && [[ -t 0 ]]; then
    read -rp "Instalar Google Chrome (exigido por plasma/apply.sh, Meta+B)? [s/N] " answer
    if [[ ${answer:-N} =~ ^[SsYy]$ ]]; then
        tmp_deb="$(mktemp --suffix=.deb)"
        curl -fsSL -o "$tmp_deb" https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
        sudo apt-get install -y "$tmp_deb"
        rm -f "$tmp_deb"
    fi
fi

if [[ ${SHELL:-} != */zsh ]] && [[ -t 0 ]]; then
    read -rp "Definir zsh como shell padrão? [S/n] " answer
    if [[ ${answer:-S} =~ ^[SsYy]?$ ]]; then
        chsh -s "$(command -v zsh)"
    fi
fi

cat <<'MSG'

Bootstrap PikaOS concluído.

Próximos passos:
  1. ./deploy.sh                          # stow (resolva conflitos de ~/.zshenv etc.)
  2. mise install                          # usage + herdr
  3. ./bootstrap/pikaos/plasma-prereqs.sh  # Krohnkite, Geometry Change, Layan, cursor
  4. PLASMA_LAUNCHER_ICON=start-here-kde ./plasma/apply.sh --apply
  5. ./theme/install-watch.sh              # kitty segue o kdeglobals
MSG
