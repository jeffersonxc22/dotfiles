# ~/.zshenv: shims do mise para shells não interativos (`zsh -c`, scripts,
# editores, apps abertos pelo Plasma). No shell interativo quem assume é o
# `mise activate zsh` do ~/.zshrc.
if [[ -d $HOME/.local/share/mise/shims ]]; then
    case ":$PATH:" in
        *":$HOME/.local/share/mise/shims:"*) ;;
        *) export PATH="$HOME/.local/share/mise/shims:$PATH" ;;
    esac
fi
