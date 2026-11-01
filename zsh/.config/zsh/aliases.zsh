# Aliases do dia a dia.

# Atalhos de configuração
alias zshconfig='$EDITOR ${ZDOTDIR:-$HOME/.config/zsh}/.zshrc'
alias zshsource='source ${ZDOTDIR:-$HOME/.config/zsh}/.zshrc'
alias nvimconfig='$EDITOR ${XDG_CONFIG_HOME:-$HOME/.config}/nvim'
alias dotfiles='cd ~/dotfiles'

# eza no lugar de ls
alias ls='eza --icons'
alias ll='eza -la --icons'
alias lt='eza --tree --level=2 --icons'

# bat no lugar de cat (no Fedora o binário já se chama bat)
if command -v bat >/dev/null 2>&1; then
    alias cat='bat --paging=never'
fi
