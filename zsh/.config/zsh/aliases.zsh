# Aliases — espelho de fish/.config/fish/config.fish e functions/{ls,ll,lt}.fish.

# Atalhos de configuração
alias fishconfig='$EDITOR ~/.config/fish/config.fish'
alias fishsource='source ~/.config/fish/config.fish'
alias zshconfig='$EDITOR ${ZDOTDIR:-$HOME/.config/zsh}/.zshrc'
alias zshsource='source ${ZDOTDIR:-$HOME/.config/zsh}/.zshrc'

# eza no lugar de ls (mesmos wraps do fish)
alias ls='eza --icons'
alias ll='eza -la --icons'
alias lt='eza --tree --level=2 --icons'

# bat no lugar de cat. No Ubuntu o pacote `bat` instala o binário como
# `batcat` (o nome `bat` conflita com outro pacote), então cobrimos os dois.
if command -v bat >/dev/null 2>&1; then
    alias cat='bat --paging=never'
elif command -v batcat >/dev/null 2>&1; then
    alias bat='batcat'
    alias cat='batcat --paging=never'
fi
