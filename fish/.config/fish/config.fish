# Carrega config base do CachyOS
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


#Init TMUX
if not set -q TMUX
    if tmux has-session 2>/dev/null
        exec tmux attach
    else
        exec tmux
    end
end


