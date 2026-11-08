#!/usr/bin/env bash
# Funções comuns dos scripts de tema (não executar direto).

FLAVOURS=(mocha macchiato frappe latte)

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
