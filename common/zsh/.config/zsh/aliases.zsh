# Aliases do dia a dia.

# Atalhos de configuração
alias zshconfig='$EDITOR ~/.zshrc'
alias zshsource='source ~/.zshrc'
alias nvimconfig='$EDITOR ${XDG_CONFIG_HOME:-$HOME/.config}/nvim'
alias dotfiles='cd ~/Projetos/dotfiles'

# eza: ls, lsa, lt e lta vêm do Omarchy; ll é só um atalho para o lsa dele.
alias ll='lsa'

# bat no lugar de cat 
if command -v bat >/dev/null 2>&1; then
    alias cat='bat --paging=never'
fi
