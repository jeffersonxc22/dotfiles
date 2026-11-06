#!/usr/bin/env bash
# Interface do install.sh: banner com o logo da distro, etapas com barra de
# progresso em degradê, tempo por etapa, resumo final e quadro de falha.
# Paleta Catppuccin Mocha em truecolor; sem cor quando NO_COLOR está definido
# ou a saída não é um terminal. Caixas só com borda esquerda: glifos Nerd Font
# têm largura variável.
#
# Uso (sourced): ui_banner <total>; step <n> <título>; ...; ui_done

_ui_color=0
[[ -t 1 && -z ${NO_COLOR:-} ]] && _ui_color=1
_rgb() { ((_ui_color)) && printf '\033[1;38;2;%s;%s;%sm' "$1" "$2" "$3"; return 0; } # _rgb r g b
_rst=''; ((_ui_color)) && _rst=$'\033[0m'
_mauve=$(_rgb 203 166 247) _sapph=$(_rgb 116 199 236) _green=$(_rgb 166 227 161)
_red=$(_rgb 243 139 168) _yellow=$(_rgb 249 226 175) _peach=$(_rgb 250 179 135)
_lav=$(_rgb 180 190 254) _text=$(_rgb 205 214 244) _ovl=$(_rgb 108 112 134)
# Arco-íris Catppuccin: cada etapa tem a sua cor no cabeçalho e no resumo.
_ui_rainbow=('245 224 220' '242 205 205' '245 194 231' '203 166 247' '243 139 168' '235 160 172'
    '250 179 135' '249 226 175' '166 227 161' '148 226 213' '137 220 235' '116 199 236' '137 180 250' '180 190 254')

_ui_total=0 _ui_n=0 _ui_title='' _ui_t0=0 _ui_start=$SECONDS
_ui_done=() # "n|título|segundos"
_ui_rule='──────────────────────────────────────────────────────────'

_ui_fmt() { printf '%02d:%02d' $(($1 / 60)) $(($1 % 60)); }
_ui_elapsed() { _ui_fmt $((SECONDS - _ui_start)); }
_ui_hue() { local c=(${_ui_rainbow[$((($1 - 1) % ${#_ui_rainbow[@]}))]}); _rgb "${c[@]}"; } # cor da etapa n

ui_banner() { # ui_banner <total de etapas>
    _ui_total=$1
    local NAME='' VERSION_ID='' VARIANT='' PRETTY_NAME=''
    # shellcheck disable=SC1091
    . /etc/os-release 2>/dev/null || true
    local distro="${NAME% Linux} ${VERSION_ID}" # "Fedora 44": acompanha cada nova versão
    local variant="${VARIANT:-KDE Plasma}"
    variant="${variant%% Desktop*}" # "KDE Plasma Desktop Edition" → "KDE Plasma"
    # Logo Fedora estilizado em blocos; o "f" é o espaço negativo.
    local logo=(
        '      ▄▄██████▄▄      '
        '   ▄██████████████▄   '
        '  ██████████▀▀▀▀▀███  '
        ' ████████▀   ▄▄▄  ███ '
        ' ████████   ████████▀ '
        ' ████▀▀▀▀     ▀▀▀███  '
        ' ████▄▄▄▄     ▄▄▄███  '
        ' ████████   ████████  '
        '  ███████   ███████   '
        '   ▀█████  ▄█████▀    '
        '      ▀▀██████▀▀      '
    )
    # Degradê azul Fedora → sapphire → lavender, linha a linha.
    local grad=('41 65 114' '52 101 164' '60 110 180' '81 162 218' '96 175 225'
        '116 199 236' '120 190 240' '137 180 250' '150 184 252' '165 187 253' '180 190 254')
    local info=(
        ''
        ''
        "$(_rgb 81 162 218)󰣛  ${distro}${_rst}"
        "${_mauve}dotfiles${_rst} ${_ovl}·${_rst} ${_text}${variant} do zero${_rst}"
        ''
        "${_peach}${_ui_total} etapas${_rst} ${_ovl}· dnf · tema · programas · PARA${_rst}"
        "${_green}idempotente${_rst} ${_ovl}· rode de novo: o feito é pulado${_rst}"
        ''
        "${_ovl}${PRETTY_NAME:-Linux}${_rst}"
        ''
        ''
    )
    local i g
    echo
    for i in "${!logo[@]}"; do
        g=(${grad[$i]})
        printf '  %s%s%s   %s\n' "$(_rgb "${g[@]}")" "${logo[$i]}" "$_rst" "${info[$i]}"
    done
    printf '  %s%s%s\n' "$_ovl" "$_ui_rule" "$_rst"
}

_ui_close() { # fecha a etapa atual com ✓ e o tempo
    ((_ui_n)) || return 0
    local dt=$((SECONDS - _ui_t0))
    _ui_done+=("$_ui_n|$_ui_title|$dt")
    printf '\n  %s✓%s %s%s%s  %s%s%s\n' "$_green" "$_rst" "$(_ui_hue "$_ui_n")" "$_ui_title" "$_rst" "$_ovl" "$(_ui_fmt "$dt")" "$_rst"
    _ui_n=0
}

step() { # step <n> <título>
    _ui_close
    _ui_n=$1 _ui_title=$2 _ui_t0=$SECONDS
    local width=40 fill=$(($1 * 40 / _ui_total)) bar='' i
    for ((i = 0; i < width; i++)); do
        if ((i < fill)); then # degradê sapphire (116,199,236) → mauve (203,166,247)
            bar+="$(_rgb $((116 + 87 * i / width)) $((199 - 33 * i / width)) $((236 + 11 * i / width)))━"
        else
            bar+="${_ovl}─"
        fi
    done
    printf '\n  %s%s %s%3d%%%s  %s󱑂 %s%s\n' "$bar" "$_rst" "$_lav" $(($1 * 100 / _ui_total)) "$_rst" "$_ovl" "$(_ui_elapsed)" "$_rst"
    printf '  %s %02d/%02d %s %s%s%s\n\n' "$(_ui_hue "$1")" "$1" "$_ui_total" "$_rst" "$_text" "$2" "$_rst"
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
        printf '  %s│%s %s %02d %s %s✓%s %s%s%*s%s %s%s%s\n' "$_mauve" "$_rst" "$(_ui_hue "$n")" "$n" "$_rst" "$_green" "$_rst" \
            "$_text" "$title" $((56 - ${#title})) '' "$_rst" "$_ovl" "$(_ui_fmt "$dt")" "$_rst"
    done
    printf '  %s╰%s%s\n' "$_mauve" "$_ui_rule" "$_rst"
    printf '\n  %s Tudo pronto em %s.%s %sReinicie para valer zsh, kernel e drivers.%s\n\n' \
        "$_green" "$(_ui_elapsed)" "$_rst" "$_text" "$_rst"
}
