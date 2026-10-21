if status is-interactive
    # Greetting
    set -g fish_greeting

    # Starship
    starship init fish | source

    # Zoxide
    zoxide init fish | source

    # FZF — key bindings (Ctrl-T, Ctrl-R, Alt-C)
    fzf_key_bindings

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
        eval (ssh-agent -c) >/dev/null
        ssh-add ~/.ssh/id_ed25519 2>/dev/null
    end

    # PATH
    fish_add_path /usr/local/go/bin
    fish_add_path ~/.local/bin

    # execução
end

# opencode
fish_add_path /home/jefferson/.opencode/bin

# Mise — fora do bloco interativo de propósito: assim o ambiente (ferramentas e
# variáveis de persona) também vale em `fish -c`, scripts e `mise run`.
mise activate fish | source
