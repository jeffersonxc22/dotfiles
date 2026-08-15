if status is-interactive
    # Config padrão do CachyOS (fastfetch, aliases de pacman/eza, !!/!$)
    source /usr/share/cachyos-fish-config/cachyos-config.fish

    # Starship
    starship init fish | source

    # Zoxide
    zoxide init fish | source

    # FZF — key bindings e fuzzy completion, tema Catppuccin Mocha
    fzf --fish | source
    source "$HOME/dotfiles/zsh/.fzf-catppuccin/themes/catppuccin-fzf-mocha.fish"

    # Mise
    mise activate fish | source

    # Variáveis de ambiente
    set -gx EDITOR nvim
    set -gx SUDO_EDITOR nvim
    set -gx BAT_THEME "Catppuccin Mocha"
    set -gx ENV_NAME (basename $HOME)

    # Aliases
    alias fishconfig="$EDITOR ~/.config/fish/config.fish"
    alias fishsource="source ~/.config/fish/config.fish"
    alias cat="bat --paging=never"

    # Garante que o ssh-agent está rodando e com a chave carregada
    if not set -q SSH_AUTH_SOCK
        eval (ssh-agent -c) > /dev/null
        ssh-add ~/.ssh/id_ed25519 2> /dev/null
    end

    # PATH
    fish_add_path /usr/local/go/bin
    fish_add_path ~/.local/bin

    # execução
    herdr
end
