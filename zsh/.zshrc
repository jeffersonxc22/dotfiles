# ~/.zshrc (Fedora KDE). Shell não interativo só lê o ~/.zshenv (shims do mise).
[[ $- != *i* ]] && return

HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
HISTSIZE=50000
SAVEHIST=50000
mkdir -p "${HISTFILE:h}"
setopt extended_history hist_expire_dups_first hist_ignore_dups hist_ignore_space \
    hist_reduce_blanks hist_verify share_history
unsetopt beep

export EDITOR=nvim
export SUDO_EDITOR=nvim
export BAT_THEME="Catppuccin Mocha"
export ENV_NAME="${ENV_NAME:-$(basename "$HOME")}"

typeset -U path PATH
path=("$HOME/.opencode/bin" "$HOME/.local/bin" $path)

# ssh-agent: sobe um se a sessão não tiver socket.
if [[ -z ${SSH_AUTH_SOCK-} ]]; then
    eval "$(ssh-agent -s)" >/dev/null
    ssh-add "$HOME/.ssh/id_ed25519" 2>/dev/null
fi

# Plugins: bootstrap/zsh-plugins.sh os reúne em ~/.local/share/zsh/plugins.
plugins="$HOME/.local/share/zsh/plugins"
[[ -d $plugins/zsh-completions/src ]] && fpath=("$plugins/zsh-completions/src" $fpath)

# O zcompdump fica no cache, não na home.
ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-$ZSH_VERSION"
mkdir -p "${ZSH_COMPDUMP:h}"
autoload -Uz compinit
compinit -d "$ZSH_COMPDUMP"
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' group-name ''
[[ -n ${LS_COLORS-} ]] && zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# fzf em Catppuccin Mocha com destaque Sapphire, como o starship. Só as cores de
# texto são fixas: bg:-1 mantém o fundo do kitty.
export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:+$FZF_DEFAULT_OPTS }--color=fg:-1,bg:-1,gutter:-1,hl:#74c7ec,fg+:#cdd6f4,bg+:#313244,hl+:#74c7ec,info:#89b4fa,prompt:#74c7ec,pointer:#74c7ec,marker:#a6e3a1,spinner:#74c7ec,header:#89b4fa,border:#45475a,label:#cdd6f4"

command -v fzf >/dev/null && eval "$(fzf --zsh)" # Ctrl-T, Ctrl-R, Alt-C (fzf >= 0.48)
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"
command -v starship >/dev/null && eval "$(starship init zsh)"
command -v mise >/dev/null && eval "$(mise activate zsh)"

# fzf-tab: completion em lista com descrição e filtro fuzzy.
# Precisa vir depois do compinit e antes do zsh-autosuggestions.
if [[ -r $plugins/fzf-tab/fzf-tab.plugin.zsh ]]; then
    source "$plugins/fzf-tab/fzf-tab.plugin.zsh"
    zstyle ':completion:*' menu no                    # o fzf-tab assume o menu
    zstyle ':completion:*:descriptions' format '[%d]' # cabeçalho de grupo
    zstyle ':fzf-tab:*' switch-group '<' '>'
    zstyle ':fzf-tab:*' fzf-flags --height=60%
    zstyle ':fzf-tab:*' use-fzf-default-opts yes      # herda as cores acima
    zstyle ':fzf-tab:complete:(cd|z):*' fzf-preview 'eza -1 --color=always --icons=auto $realpath'
    # Arquivos e pastas em ls/eza/bat/editores: pasta lista com eza, arquivo mostra com bat.
    # O ls é alias de eza, e o zsh completa o alias como o comando expandido.
    zstyle ':fzf-tab:complete:(ls|eza|bat|cat|less|nvim|vim|cp|mv|rm):*' fzf-preview \
        '[[ -d $realpath ]] && eza -1 --color=always --icons=auto $realpath || bat --color=always --style=numbers --line-range=:200 $realpath 2>/dev/null'
fi

# Sugestões do histórico enquanto digita.
[[ -r $plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] &&
    source "$plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"

source "$HOME/.config/zsh/aliases.zsh"
source "$HOME/.config/zsh/functions.zsh"

# Último: o syntax-highlighting reescreve os widgets já existentes.
[[ -r $plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] &&
    source "$plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
unset plugins
