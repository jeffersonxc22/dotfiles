#!/usr/bin/env bash
# Funções comuns dos scripts de tema (não executar direto).

FLAVOURS=(mocha macchiato frappe latte)
ACCENTS=(rosewater flamingo pink mauve red maroon peach yellow green teal sky sapphire blue lavender)

normalize_flavour() {
    local value="${1:-mocha}"
    value="${value,,}"
    case "$value" in
        mocha | macchiato | frappe | frappé | latte)
            [[ $value == frappé ]] && value=frappe
            printf '%s\n' "$value"
            ;;
        *)
            echo "ERRO: flavour inválido: '$1' (use: ${FLAVOURS[*]})" >&2
            return 1
            ;;
    esac
}

normalize_accent() {
    local value="${1:-sapphire}"
    value="${value,,}"
    local accent
    for accent in "${ACCENTS[@]}"; do
        if [[ $value == "$accent" ]]; then
            printf '%s\n' "$value"
            return 0
        fi
    done
    echo "ERRO: accent inválido: '$1' (use: ${ACCENTS[*]})" >&2
    return 1
}

capitalize_flavour() {
    case "$1" in
        mocha) printf 'Mocha\n' ;;
        macchiato) printf 'Macchiato\n' ;;
        frappe) printf 'Frappe\n' ;;
        latte) printf 'Latte\n' ;;
    esac
}

capitalize_accent() {
    local value="$1"
    printf '%s%s\n' "${value:0:1}" "${value:1}" | sed 's/^./\U&/'
}

scheme_name() {
    printf 'Catppuccin%s%s\n' "$(capitalize_flavour "$1")" "$(capitalize_accent "$2")"
}

lookandfeel_name() {
    printf 'Catppuccin-%s-%s\n' "$(capitalize_flavour "$1")" "$(capitalize_accent "$2")"
}

kde_get() {
    local group="$1" key="$2"
    kreadconfig6 --file "${KDE_CONFIG:-$HOME/.config/kdeglobals}" --group "$group" --key "$key"
}

# Converte "30, 30, 46" em "#1e1e2e".
rgb_to_hex() {
    local r g b
    IFS=',' read -r r g b <<<"$1"
    r="${r//[[:space:]]/}"
    g="${g//[[:space:]]/}"
    b="${b//[[:space:]]/}"
    if [[ ! $r =~ ^[0-9]+$ || ! $g =~ ^[0-9]+$ || ! $b =~ ^[0-9]+$ ]]; then
        return 1
    fi
    printf '#%02x%02x%02x\n' "$r" "$g" "$b"
}

# set_gtk_key <arquivo> <chave> <valor>
set_gtk_key() {
    local file="$1" key="$2" value="$3"
    [[ -f $file ]] || return 0

    if grep -qE "^[[:space:]]*${key}=" "$file"; then
        sed -i -E "s|^[[:space:]]*${key}=.*|${key}=${value}|" "$file"
    elif grep -q '^\[Settings\]' "$file"; then
        sed -i "/^\[Settings\]/a ${key}=${value}" "$file"
    else
        printf '\n[Settings]\n%s=%s\n' "$key" "$value" >>"$file"
    fi
}

require_kde_tools() {
    local cmd
    for cmd in kreadconfig6 kwriteconfig6 plasma-apply-colorscheme; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo "ERRO: '$cmd' não encontrado. Instale o Plasma/KDE." >&2
            exit 1
        fi
    done
}
