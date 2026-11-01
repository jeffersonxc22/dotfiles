#!/usr/bin/env bash
# Instala as dependências do Fedora usadas pelos dotfiles.
#
# Uso: ./bootstrap/install.sh
#
# Roda como usuário normal (usa sudo só para o dnf) e é idempotente.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$repo/bootstrap/lib.sh"

if [[ ! -r /etc/fedora-release ]]; then
    echo "ERRO: este script é para Fedora (não encontrei /etc/fedora-release)." >&2
    exit 1
fi

echo "== Pacotes do Fedora"
mapfile -t packages < <(grep -vE '^[[:space:]]*(#|$)' "$repo/bootstrap/packages.txt")
sudo dnf install -y "${packages[@]}"

echo "== Plugins de zsh fora do dnf"
"$repo/bootstrap/zsh-plugins.sh"

mkdir -p "$HOME/.local/bin" "$HOME/.local/share/zsh/plugins"

echo "== Ferramentas instaladas fora do dnf"
for tool in starship mise; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        cat >&2 <<EOF
aviso: '$tool' não está no PATH.
       - starship: https://starship.rs/guide/#%F0%9F%9A%80-installation
       - mise:     https://mise.jdx.dev/getting-started.html
EOF
    fi
done

if [[ ${SHELL:-} != */zsh ]] && [[ -t 0 ]]; then
    read -rp "Definir zsh como shell padrão? [S/n] " answer
    if [[ ${answer:-S} =~ ^[SsYy]?$ ]]; then
        chsh -s "$(command -v zsh)"
    fi
fi

cat <<'EOF'

Bootstrap concluído.

Próximos passos:
  1. ./deploy.sh                 # stow dos pacotes em $HOME
  2. ./theme/install.sh          # tema Catppuccin, cursor, ícones e Flatpak
  3. sudo ./theme/greeter.sh     # fonte/cursor/tema na tela de login
  4. ./theme/install-watch.sh    # cores do kitty seguem o kdeglobals

Observação: neste Fedora o login é o Plasma Login Manager (plasmalogin),
não o SDDM. O script do greeter escreve em /var/lib/plasmalogin.
EOF
