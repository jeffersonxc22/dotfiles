#!/usr/bin/env bash
# Interface do install.sh: banner, etapas com barra de progresso, tempo por
# etapa, resumo final e quadro de falha. Paleta Catppuccin Mocha em truecolor.
# Sem cor quando NO_COLOR está definido ou a saída não é um terminal.
# Caixas só com borda esquerda: glifos Nerd Font têm largura variável.
#
# Uso (sourced): ui_banner <total>; step <n> <título>; ...; ui_done

if [[ -t 1 && -z ${NO_COLOR:-} ]]; then
    _c() { printf '\033[1;38;2;%sm' "$1"; }
    _rst=$'\033[0m'
    _mauve=$(_c '203;166;247') _sapph=$(_c '116;199;236') _green=$(_c '166;227;161')
    _red=$(_c '243;139;168') _yellow=$(_c '249;226;175') _peach=$(_c '250;179;135')
    _lav=$(_c '180;190;254') _text=$'\033[38;2;205;214;244m' _ovl=$'\033[38;2;108;112;134m'
    unset -f _c
else
    _rst='' _mauve='' _sapph='' _green='' _red='' _yellow='' _peach='' _lav='' _text='' _ovl=''
fi

_ui_total=0 _ui_n=0 _ui_title='' _ui_t0=0 _ui_start=$SECONDS
_ui_done=() # "n|título|segundos"
_ui_rule='──────────────────────────────────────────────────'

_ui_fmt() { printf '%02d:%02d' $(($1 / 60)) $(($1 % 60)); }
_ui_elapsed() { _ui_fmt $((SECONDS - _ui_start)); }

ui_banner() { # ui_banner <total de etapas>
    _ui_total=$1
    local os; os="$(. /etc/os-release 2>/dev/null; echo "${PRETTY_NAME:-Linux}")"
    printf '\n  %s╭─%s %s󰣛  dotfiles%s %s·%s %sFedora KDE do zero%s\n' \
        "$_mauve" "$_rst" "$_sapph" "$_rst" "$_ovl" "$_rst" "$_text" "$_rst"
    printf '  %s│%s  %s%s · %s etapas · rode de novo quando quiser: o feito é pulado%s\n' \
        "$_mauve" "$_rst" "$_ovl" "$os" "$_ui_total" "$_rst"
    printf '  %s╰%s%s\n' "$_mauve" "$_ui_rule" "$_rst"
}

_ui_close() { # fecha a etapa atual com ✓ e o tempo
    ((_ui_n)) || return 0
    local dt=$((SECONDS - _ui_t0))
    _ui_done+=("$_ui_n|$_ui_title|$dt")
    printf '\n  %s✓%s %s%s%s  %s%s%s\n' "$_green" "$_rst" "$_text" "$_ui_title" "$_rst" "$_ovl" "$(_ui_fmt "$dt")" "$_rst"
    _ui_n=0
}

step() { # step <n> <título>
    _ui_close
    _ui_n=$1 _ui_title=$2 _ui_t0=$SECONDS
    local width=32 fill=$(($1 * 32 / _ui_total)) bar='' i
    for ((i = 0; i < width; i++)); do
        if ((i < fill)); then bar+="${_sapph}━"; else bar+="${_ovl}─"; fi
    done
    printf '\n  %s%s %s%3d%%%s  %s%s%s\n' "$bar" "$_rst" "$_lav" $(($1 * 100 / _ui_total)) "$_rst" "$_ovl" "$(_ui_elapsed)" "$_rst"
    printf '  %s %02d/%02d %s %s%s%s\n\n' "$_mauve" "$1" "$_ui_total" "$_rst" "$_text" "$2" "$_rst"
}

ui_warn() { printf '  %s⚠  %s%s\n' "$_yellow" "$*" "$_rst" >&2; }

ui_fail() { # trap ERR: mostra onde parou e como continuar
    {
        printf '\n  %s╭─ ✗ Falhou na etapa %02d/%02d%s\n' "$_red" "$_ui_n" "$_ui_total" "$_rst"
        printf '  %s│%s  %s%s%s  %s(código %s, após %s)%s\n' "$_red" "$_rst" "$_text" "$_ui_title" "$_rst" "$_ovl" "$1" "$(_ui_elapsed)" "$_rst"
        printf '  %s│%s  %sCorrija o erro acima e rode ./bootstrap/install.sh de novo.%s\n' "$_red" "$_rst" "$_peach" "$_rst"
        printf '  %s╰%s%s\n' "$_red" "$_ui_rule" "$_rst"
    } >&2
}

ui_done() { # resumo final
    _ui_close
    printf '\n  %s╭─ 󰄬 Resumo%s\n' "$_mauve" "$_rst"
    local entry n title dt
    for entry in "${_ui_done[@]}"; do
        IFS='|' read -r n title dt <<<"$entry"
        title=${title:0:56} # ${#} conta caracteres; printf %-Ns contaria bytes e desalinharia acentos
        printf '  %s│%s %s%02d%s %s✓%s %s%s%*s%s %s%s%s\n' "$_mauve" "$_rst" "$_ovl" "$n" "$_rst" "$_green" "$_rst" \
            "$_text" "$title" $((56 - ${#title})) '' "$_rst" "$_ovl" "$(_ui_fmt "$dt")" "$_rst"
    done
    printf '  %s╰%s%s\n' "$_mauve" "$_ui_rule" "$_rst"
    printf '\n  %s Tudo pronto em %s.%s %sReinicie para valer zsh, kernel e drivers.%s\n\n' \
        "$_green" "$(_ui_elapsed)" "$_rst" "$_text" "$_rst"
}
