# ~/.config/fish/user.fish — suas customizações, carregado por último.
# Portado de jeffersonxc22/dotfiles em 2026-10-25 (triagem da máquina Ubuntu).
# O que já é coberto pelo Ryoku (zoxide, mise, fzf, starship, eza, fastfetch)
# NÃO está repetido aqui.

# --- atalhos de configuração ---------------------------------------------
alias fishconfig '$EDITOR ~/.config/fish/config.fish'
alias fishsource 'source ~/.config/fish/config.fish'

# --- eza: listagem longa (o Ryoku já cobre ls/lsa/lt/lta) ----------------
if command -q eza
    alias ll 'eza -la --group-directories-first --icons=auto'
end

# --- bat como cat, com o tema que você já usava --------------------------
if command -q bat
    set -gx BAT_THEME "Catppuccin Mocha"
    alias cat 'bat --paging=never'
end

# --- ssh-agent: garante o agente com a chave carregada -------------------
# Só em shell interativo, e só se ainda não houver agente no ambiente.
if status is-interactive; and not set -q SSH_AUTH_SOCK; and test -f ~/.ssh/id_ed25519
    eval (ssh-agent -c) >/dev/null
    ssh-add ~/.ssh/id_ed25519 2>/dev/null
end

# --- personas do mise (Kode-D) ------------------------------------------
# O mise só exporta KODE_D_PERSONA; os caminhos derivados são calculados aqui.
# Vive em user.fish (e não em conf.d/) porque ~/.config/fish/conf.d é do Ryoku.
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

# O mise já exportou a variável antes deste arquivo: aplica uma vez agora.
if set -q KODE_D_PERSONA
    __mise_persona_env
end
