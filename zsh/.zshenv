# Ponto de entrada do zsh no Fedora, instalado em ~/.zshenv pelo Stow.
#
# O restante da configuração vive em ~/.config/zsh (padrão XDG). Este é o único
# arquivo que precisa ficar no $HOME porque é o primeiro que o zsh lê e define
# o ZDOTDIR.

export ZDOTDIR="${ZDOTDIR:-$HOME/.config/zsh}"

# O .zcompdump é gravado no cache (ver .zshrc). Desligar o compinit global
# evita rodar a inicialização duas vezes em distros que já a fazem no /etc/zshrc.
skip_global_compinit=1

# Shims do mise: deixam as ferramentas disponíveis em shells não interativos
# (`zsh -c`, scripts, editores). No shell interativo quem assume é o
# `mise activate zsh` do .zshrc.
if [[ -d $HOME/.local/share/mise/shims ]]; then
    case ":$PATH:" in
        *":$HOME/.local/share/mise/shims:"*) ;;
        *) export PATH="$HOME/.local/share/mise/shims:$PATH" ;;
    esac
fi
