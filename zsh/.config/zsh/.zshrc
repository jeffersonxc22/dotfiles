# Configuração interativa do zsh.
#
# Espelho do fish/.config/fish/config.fish: mesmas variáveis, aliases e
# funções, para que trocar de shell não mude o ambiente de trabalho.
#
# Arquivos companheiros (todos em ~/.config/zsh):
#   aliases.zsh        aliases (ls/ll/lt, cat, atalhos de config)
#   functions.zsh      funções do dia a dia (git-use-ssh, herdr, ...)
#   mise-persona.zsh   deriva CLAUDE_CONFIG_DIR/CODEX_HOME do KODE_D_PERSONA
#   plugins.txt        lista de plugins usada por install/install-zsh-plugins.sh

# ---------------------------------------------------------------------------
# Histórico
# ---------------------------------------------------------------------------
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
HISTSIZE=50000
SAVEHIST=50000
mkdir -p "${HISTFILE:h}"

setopt extended_history      # guarda data/hora (e duração) de cada comando
setopt hist_expire_dups_first
setopt hist_ignore_dups      # não repete comandos idênticos em sequência
setopt hist_ignore_space     # comando começando com espaço não entra no histórico
setopt hist_reduce_blanks
setopt hist_verify
setopt share_history         # compartilha histórico entre abas abertas

# ---------------------------------------------------------------------------
# Variáveis de ambiente
# ---------------------------------------------------------------------------
export EDITOR=nvim
export SUDO_EDITOR=nvim
export BAT_THEME="Catppuccin Mocha"
export ENV_NAME="${ENV_NAME:-$(basename "$HOME")}"

# Sem barulho ao completar/errar
unsetopt beep

# ---------------------------------------------------------------------------
# PATH (mesma ordem do fish_add_path)
# ---------------------------------------------------------------------------
typeset -U path PATH
path=(
    "$HOME/.opencode/bin"
    /usr/local/go/bin
    "$HOME/.local/bin"
    $path
)

# ---------------------------------------------------------------------------
# ssh-agent (mesmo comportamento do fish: sobe se não houver socket)
# ---------------------------------------------------------------------------
if [[ -z ${SSH_AUTH_SOCK-} ]]; then
    eval "$(ssh-agent -s)" >/dev/null
    ssh-add "$HOME/.ssh/id_ed25519" 2>/dev/null
fi

# ---------------------------------------------------------------------------
# Completions
# ---------------------------------------------------------------------------
ZSH_PLUGIN_DIR="${ZSH_PLUGIN_DIR:-$HOME/.local/share/zsh/plugins}"
fpath=("$ZSH_PLUGIN_DIR/zsh-completions/src" $fpath)

# O zcompdump fica no cache (e não no ZDOTDIR, que é um symlink do stow).
ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-$ZSH_VERSION"
mkdir -p "${ZSH_COMPDUMP:h}"

autoload -Uz compinit
compinit -d "$ZSH_COMPDUMP"

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '[%d]'
[[ -n ${LS_COLORS-} ]] && zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# fzf-tab: escolha de completions com preview
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always --icons "$realpath"'
zstyle ':fzf-tab:*' fzf-flags --height=60%

# ---------------------------------------------------------------------------
# Plugins (clonados por install/install-zsh-plugins.sh)
# ---------------------------------------------------------------------------
__zsh_source_plugin() {
    [[ -r $1 ]] && source "$1"
    return 0
}

__zsh_source_plugin "$ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"
__zsh_source_plugin "$ZSH_PLUGIN_DIR/fzf-tab/fzf-tab.zsh"

# Último da fila: o syntax-highlighting reescreve os widgets já existentes.
__zsh_source_plugin "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

unfunction __zsh_source_plugin

# ---------------------------------------------------------------------------
# fzf, zoxide, starship
# ---------------------------------------------------------------------------
if command -v fzf >/dev/null 2>&1; then
    eval "$(fzf --zsh)" # Ctrl-T, Ctrl-R, Alt-C (fzf >= 0.48)
fi

if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi

# ---------------------------------------------------------------------------
# Mise
# ---------------------------------------------------------------------------
# Este arquivo só roda no shell interativo; os shims do .zshenv cobrem
# `zsh -c`, scripts e editores.
if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate zsh)"
fi

# Persona (depende do KODE_D_PERSONA exportado pelo mise): carregada depois da
# ativação para que os hooks fiquem na ordem certa.
source "${ZDOTDIR:-$HOME/.config/zsh}/mise-persona.zsh"

# ---------------------------------------------------------------------------
# Aliases e funções
# ---------------------------------------------------------------------------
source "${ZDOTDIR:-$HOME/.config/zsh}/aliases.zsh"
source "${ZDOTDIR:-$HOME/.config/zsh}/functions.zsh"
