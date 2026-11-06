#!/usr/bin/env bash
# Instala e configura o Fedora KDE do zero, na ordem: dnf → sistema → TUI →
# shell → dotfiles → ferramentas → terminal → tema → login → programas →
# teclado, áreas de trabalho, tiling, atalhos e efeitos do Plasma → PARA.
# Sempre de forma oficial: pacote do Fedora, repositório do fabricante ou,
# sem rpm, o instalador oficial do projeto.
#
# Uso: ./bootstrap/install.sh   (logo após clonar, dentro da sessão Plasma)
#
# Roda como usuário normal (pede sudo quando precisa) e é idempotente: rodar
# de novo só completa o que faltou.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=ui.sh
source "$repo/bootstrap/ui.sh"
[[ $EUID -ne 0 ]] || { echo "Rode como usuário normal (sem sudo)." >&2; exit 1; }
[[ -r /etc/fedora-release ]] || { echo "ERRO: este script é para Fedora (não encontrei /etc/fedora-release)." >&2; exit 1; }
busctl --user introspect org.kde.plasmashell /PlasmaShell >/dev/null 2>&1 \
    || { echo "ERRO: rode dentro de uma sessão Plasma (as etapas de tema usam o plasmashell)." >&2; exit 1; }
ui_banner 16
sudo -v
trap 'ui_fail $?' ERR

step 1 "dnf: 20 downloads paralelos (máximo aceito)"
sudo dnf config-manager setopt max_parallel_downloads=20

step 2 "Atualizando o sistema"
sudo dnf upgrade -y --refresh

step 3 "Sistema: RPM Fusion, openh264, codecs e drivers"
v="$(rpm -E %fedora)"
rpm -q rpmfusion-free-release rpmfusion-nonfree-release >/dev/null 2>&1 || sudo dnf install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$v.noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$v.noarch.rpm"
sudo dnf config-manager setopt fedora-cisco-openh264.enabled=1
sudo dnf install -y pciutils # lspci, usado pelo drivers.sh
"$repo/bootstrap/drivers.sh"

step 4 "Pacotes do Fedora (TUI, base e tema)"
mapfile -t packages < <(grep -vE '^[[:space:]]*(#|$)' "$repo/bootstrap/packages.txt")
sudo dnf install -y --skip-unavailable "${packages[@]}"

step 5 "mise (COPR oficial do autor) e starship (instalador oficial; sem rpm)"
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"
rpm -q mise >/dev/null 2>&1 || { sudo dnf copr enable -y jdxcode/mise && sudo dnf install -y mise; }
command -v starship >/dev/null 2>&1 || curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"

step 6 "zsh como shell padrão"
[[ $(getent passwd "$USER" | cut -d: -f7) == "$(command -v zsh)" ]] || chsh -s "$(command -v zsh)"

step 7 "Plugins de zsh"
"$repo/bootstrap/zsh-plugins.sh"
themes="$(bat --config-dir)/themes"
if [[ ! -f $themes/Catppuccin\ Mocha.tmTheme ]]; then # BAT_THEME do .zshrc
    mkdir -p "$themes"
    curl -fsSL -o "$themes/Catppuccin Mocha.tmTheme" \
        "https://raw.githubusercontent.com/catppuccin/bat/main/themes/Catppuccin%20Mocha.tmTheme"
    bat cache --build >/dev/null
fi

step 8 "Stow dos dotfiles"
"$repo/deploy.sh"

step 9 "Ferramentas do mise (mise/.config/mise/config.toml)"
mise install

step 10 "kitty oficial como terminal padrão, com cores seguindo o KDE"
"$repo/bootstrap/kitty-official.sh"
"$repo/theme/install-watch.sh"

step 11 "Plasma: Layan, Krohnkite, Geometry Change e tema Catppuccin"
"$repo/plasma/prereqs.sh"
"$repo/plasma/theme.sh"

step 12 "Tela de login"
sudo "$repo/theme/greeter.sh"

step 13 "Programas: Google Chrome, Slack e Claude Code"
# O rpm do Chrome adiciona o repositório do Google; atualiza pelo dnf.
command -v google-chrome-stable >/dev/null 2>&1 \
    || sudo dnf install -y https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
[[ $(xdg-settings get default-web-browser 2>/dev/null) == google-chrome.desktop ]] \
    || xdg-settings set default-web-browser google-chrome.desktop
if ! rpm -q slack >/dev/null 2>&1; then
    # shortcut: a Slack não publica URL "latest" nem repositório; o link vem do HTML da página de download. Atualize rodando de novo.
    slack_rpm="$(curl -fsSL 'https://slack.com/downloads/instructions/linux?ddl=1&build=rpm' \
        | grep -oE 'https://downloads\.slack-edge\.com/desktop-releases/linux/x64/[^"]+\.rpm' | head -1 || true)"
    if [[ -n $slack_rpm ]]; then sudo dnf install -y "$slack_rpm"
    else ui_warn "link do .rpm do Slack não encontrado; instale por https://slack.com/downloads/linux"; fi
fi
if ! rpm -q claude-code >/dev/null 2>&1; then # repositório dnf oficial (code.claude.com/docs/en/setup)
    sudo tee /etc/yum.repos.d/claude-code.repo >/dev/null <<'EOF'
[claude-code]
name=Claude Code
baseurl=https://downloads.claude.ai/claude-code/rpm/stable
enabled=1
gpgcheck=1
gpgkey=https://downloads.claude.ai/keys/claude-code.asc
EOF
    sudo dnf install -y claude-code
fi

step 14 "Plasma: teclado (keyd), áreas de trabalho, tiling Krohnkite, atalhos do KWin e efeitos"
"$repo/bootstrap/keyd.sh"
# 10 áreas de trabalho, Krohnkite (BTree, gaps, Monocle), Geometry Change e
# wobbly windows, atalhos (Meta+1..0, Meta+T kitty, Meta+B Chrome...) e painel.
"$repo/plasma/apply.sh" --apply

step 15 "Home no método PARA"
"$repo/bootstrap/para.sh"

step 16 "Conferência"
"$repo/bootstrap/verify.sh" || true

ui_done
