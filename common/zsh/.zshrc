# ~/.zshrc: zsh do jeito oficial do Omarchy (pacote omarchy-zsh).
#
# O `omarchy-setup-zsh` cria este arquivo a partir de
# /usr/share/omarchy-zsh/templates/zshrc e troca o ~/.bashrc por um que faz
# `exec zsh` (não usa chsh). Abaixo está o mesmo template, mais as minhas
# personalizações no fim, como o README do omarchy-zsh recomenda.

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Load zsh options, keybindings, and completion
[[ -f /usr/share/omarchy-zsh/shell/zoptions ]] && source /usr/share/omarchy-zsh/shell/zoptions

# Load shared shell configuration (aliases, functions, environment, tool init)
[[ -f /usr/share/omarchy-zsh/shell/all ]] && source /usr/share/omarchy-zsh/shell/all

# ---------------------------------------------------------------------------
# Personalizações (têm prioridade sobre os padrões do Omarchy)
# ---------------------------------------------------------------------------

export BAT_THEME="Catppuccin Mocha"
export ENV_NAME="${ENV_NAME:-$(basename "$HOME")}"

typeset -U path PATH
path=("$HOME/.opencode/bin" $path)

# ssh-agent: sobe um se a sessão não tiver socket.
if [[ -z ${SSH_AUTH_SOCK-} ]]; then
    eval "$(ssh-agent -s)" >/dev/null
    ssh-add "$HOME/.ssh/id_ed25519" 2>/dev/null
fi

# Sugestões do histórico enquanto digita (pacote zsh-autosuggestions).
[[ -r /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] &&
    source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

source "$HOME/.config/zsh/aliases.zsh"
source "$HOME/.config/zsh/functions.zsh"

# try: o Omarchy usa ~/Work/tries; aqui a pasta de trabalho é ~/Projetos (PARA).
if command -v try >/dev/null; then
    eval "$(command try init ~/Projetos/tries)"
fi
