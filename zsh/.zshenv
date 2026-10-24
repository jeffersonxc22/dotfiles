# Ponto de entrada do zsh.
#
# Mantém o resto da configuração em ~/.config/zsh (padrão XDG), do mesmo jeito
# que o fish vive em ~/.config/fish. Este é o único arquivo que precisa ficar
# no $HOME, porque é o primeiro que o zsh lê e define o ZDOTDIR.

export ZDOTDIR="${ZDOTDIR:-$HOME/.config/zsh}"

# Shims do mise: deixam as ferramentas disponíveis em shells não interativos
# (`zsh -c`, scripts, editores). No shell interativo quem assume é o
# `mise activate zsh` do .zshrc.
if [[ -d $HOME/.local/share/mise/shims ]]; then
    case ":$PATH:" in
        *":$HOME/.local/share/mise/shims:"*) ;;
        *) export PATH="$HOME/.local/share/mise/shims:$PATH" ;;
    esac
fi
