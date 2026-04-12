#  Carrega config base do CachyOS
source /usr/share/cachyos-fish-config/cachyos-config.fish

# Starship
starship init fish | source

# Zoxide
zoxide init fish | source

# FZF — key bindings e fuzzy completion
fzf --fish | source

# mise
mise activate fish | source

# Variáveis de ambiente
set -gx EDITOR nvim
set -gx SUDO_EDITOR nvim
set -gx PGHOST /var/run/postgresql

# PATH
fish_add_path /usr/local/go/bin
fish_add_path ~/.local/bin

# TMUX
if status is-interactive && not set -q TMUX
    new_tmux
end

