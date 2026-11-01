#!/usr/bin/env bash
# Instala e aplica toda a identidade visual Catppuccin.
#
# Uso: ./theme/install.sh [flavour] [accent]
#      padrão: mocha sapphire
#
# Precisa de sudo para instalar temas em /usr/share. O cursor da tela de login
# é configurado à parte: sudo ./theme/greeter.sh <flavour> <accent>
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=common.sh
source "$repo/theme/common.sh"

flavour="$(normalize_flavour "${1:-mocha}")"
accent="$(normalize_accent "${2:-sapphire}")"
if [[ $accent != sapphire ]]; then
    echo 'ERRO: apenas sapphire é instalado automaticamente.' >&2
    exit 1
fi

"$repo/theme/catppuccin-kde.sh"
"$repo/theme/future-cursors.sh"
"$repo/theme/apply.sh" "$flavour" "$accent"
"$repo/theme/install-watch.sh"

cat <<EOF

Tema instalado.

Para a tela de login (Plasma Login Manager):
  sudo $repo/theme/greeter.sh $flavour $accent

Trocar de flavour/accent depois:
  $repo/theme/apply.sh <flavour> <accent>
EOF
