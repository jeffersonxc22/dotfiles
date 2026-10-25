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

# --- contas do Kode-D ---------------------------------------------------
# CLAUDE_CONFIG_DIR e CODEX_HOME vêm inteiros do mise
# (~/.config/mise/config.toml, com override por .mise.toml no projeto).
# Não há função aqui: uma camada só evita divergir do que o mise exporta.
