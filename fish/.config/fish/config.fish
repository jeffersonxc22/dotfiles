#  Carrega config base do CachyOS

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

# Garante que o ssh-agent está rodando e com a chave carregada
if not set -q SSH_AUTH_SOCK
    eval (ssh-agent -c) > /dev/null
    ssh-add ~/.ssh/id_ed25519 2> /dev/null
end


# PATH
fish_add_path /usr/local/go/bin
fish_add_path ~/.local/bin


# AWS Profile Default
asp kumo
