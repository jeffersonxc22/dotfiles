# Persona de configuração do Kode/claude/codex.
#
# O mise só exporta KODE_D_PERSONA (o "gatilho"): o valor padrão vem do
# mise global (~/.config/mise/config.toml) e cada projeto pode sobrescrever
# com um mise.toml próprio. Os caminhos derivados são calculados aqui, a
# cada mudança da variável — inclusive ao entrar/sair de um projeto.
function __mise_persona_env --on-variable KODE_D_PERSONA --description 'Deriva KODE_D_PERSONA_DIR, CLAUDE_CONFIG_DIR e CODEX_HOME'
    if test -z "$KODE_D_PERSONA"
        set -e KODE_D_PERSONA_DIR
        set -e CLAUDE_CONFIG_DIR
        set -e CODEX_HOME
        return
    end

    set -gx KODE_D_PERSONA_DIR "$HOME/.local/share/$KODE_D_PERSONA"
    set -gx CLAUDE_CONFIG_DIR "$KODE_D_PERSONA_DIR/claude"
    set -gx CODEX_HOME "$KODE_D_PERSONA_DIR/codex"
end

# Se a variável já veio do ambiente (shell pai, systemd, etc.), aplica agora.
# Caso contrário o mise dispara o handler ao ativar o ambiente no prompt.
if set -q KODE_D_PERSONA
    __mise_persona_env
end
