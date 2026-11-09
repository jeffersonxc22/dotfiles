# Aliases do dia a dia.

# Atalhos de configuração
alias zshconfig='$EDITOR ~/.zshrc'
alias zshsource='source ~/.zshrc'
alias nvimconfig='$EDITOR ${XDG_CONFIG_HOME:-$HOME/.config}/nvim'
alias dotfiles='cd ~/Projetos/dotfiles'

# eza no lugar de ls
alias ls='eza --icons'
alias ll='eza -la --icons'
alias lt='eza --tree --level=2 --icons'

# bat no lugar de cat 
if command -v bat >/dev/null 2>&1; then
    alias cat='bat --paging=never'
fi
