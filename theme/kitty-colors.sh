#!/usr/bin/env bash
# Gera ~/.cache/dotfiles/kitty-theme.conf a partir do kdeglobals.
#
# O arquivo inclui a paleta ANSI Catppuccin do flavour atual e sobrescreve
# fundo, texto, cursor e seleção com os valores exatos do KDE.
#
# Uso: ./theme/kitty-colors.sh
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../bootstrap/lib.sh
source "$repo/bootstrap/lib.sh"
# shellcheck source=common.sh
source "$repo/theme/common.sh"

require_cmd kreadconfig6

scheme="$(kde_get General ColorScheme)"
lower="${scheme,,}"

case "$lower" in
    *mocha*) flavour=mocha ;;
    *macchiato*) flavour=macchiato ;;
    *frapp*) flavour=frappe ;;
    *latte*) flavour=latte ;;
    *)
        bg_probe="$(kde_get "Colors:View" BackgroundNormal)"
        hex="$(rgb_to_hex "$bg_probe" 2>/dev/null || true)"
        if [[ -n $hex ]]; then
            r=$((16#${hex:1:2}))
            g=$((16#${hex:3:2}))
            b=$((16#${hex:5:2}))
            if (((r * 2126 + g * 7152 + b * 722) / 10000 > 127)); then
                flavour=latte
            else
                flavour=mocha
            fi
        else
            flavour=mocha
        fi
        ;;
esac

bg="$(rgb_to_hex "$(kde_get "Colors:View" BackgroundNormal)")" || bg="#1e1e2e"
fg="$(rgb_to_hex "$(kde_get "Colors:View" ForegroundNormal)")" || fg="#cdd6f4"
accent="$(rgb_to_hex "$(kde_get "Colors:Selection" BackgroundNormal)")" || accent="#74c7ec"
selection_fg="$(rgb_to_hex "$(kde_get "Colors:Selection" ForegroundNormal)")" || selection_fg="$bg"
crust="$(rgb_to_hex "$(kde_get "Colors:Window" BackgroundAlternate)")" || crust="#11111b"

out="$HOME/.cache/dotfiles/kitty-theme.conf"
mkdir -p "$(dirname "$out")"

cat >"$out" <<EOF
# Gerado por theme/kitty-colors.sh a partir de ~/.config/kdeglobals.
# Não edite: rode o script de novo (ou theme/apply.sh).
include $HOME/.config/kitty/themes/$flavour.conf

background $bg
foreground $fg
cursor $accent
cursor_text_color $bg
selection_background $accent
selection_foreground $selection_fg
active_border_color $accent
inactive_border_color $crust
EOF

echo "kitty: flavour $flavour, fundo $bg, accent $accent -> $out"

# Recarrega instâncias abertas (SIGUSR1 faz o kitty reler a config).
pkill -USR1 -x kitty 2>/dev/null || true
