# Persona de configuração do Kode/claude/codex — par do
# fish/.config/fish/conf.d/mise-persona.fish.
#
# O mise só exporta KODE_D_PERSONA (o "gatilho"): o valor padrão vem do
# mise global (~/.config/mise/config.toml) e cada projeto pode sobrescrever
# com um mise.toml próprio. Os caminhos derivados são recalculados a cada
# prompt/troca de diretório, já que no zsh não existe `--on-variable`.

__mise_persona_env() {
    if [[ -z ${KODE_D_PERSONA-} ]]; then
        unset KODE_D_PERSONA_DIR CLAUDE_CONFIG_DIR CODEX_HOME
        return
    fi

    export KODE_D_PERSONA_DIR="$HOME/.local/share/$KODE_D_PERSONA"
    export CLAUDE_CONFIG_DIR="$KODE_D_PERSONA_DIR/claude"
    export CODEX_HOME="$KODE_D_PERSONA_DIR/codex"
}

# Sentinela: distingue "nunca aplicado" de "aplicado com valor vazio".
__mise_persona_last="__unset__"

__mise_persona_refresh() {
    local atual="${KODE_D_PERSONA-__unset__}"
    [[ $atual == "$__mise_persona_last" ]] && return
    __mise_persona_last=$atual
    __mise_persona_env
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd __mise_persona_refresh
add-zsh-hook chpwd __mise_persona_refresh

# Aplica já na primeira carga (o valor pode ter vindo do shell pai, systemd
# ou do próprio mise activate).
__mise_persona_refresh
