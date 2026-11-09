#!/usr/bin/env bash
# Home no método PARA: Projetos, Áreas, Recursos e Arquivados.
# - Desktop e Público ficam em Projetos; Documentos em Áreas; Downloads, Imagens,
#   Músicas, Vídeos e Modelos em Recursos (caminhos em omarchy/xdg/user-dirs.dirs).
# - O conteúdo de um ~/Work antigo (pasta de trabalho padrão do Omarchy) vai para
#   ~/Projetos, e ~/Work deixa de existir; o `try` usa ~/Projetos/tries (.zshrc).
# - Os dotfiles ficam em ~/Projetos/dotfiles, sem link na home.
# Idempotente: nunca apaga conteúdo; pastas padrão só saem se estiverem vazias.
set -euo pipefail

mkdir -p "$HOME"/{Projetos,Áreas,Recursos,Arquivados}
mkdir -p "$HOME/Projetos"/{Desktop,Público} "$HOME/Áreas/Documentos"
mkdir -p "$HOME/Recursos"/{Downloads,Imagens/{Screenshots,Wallpapers},Músicas,Vídeos,Modelos}

if [[ -d $HOME/Work && ! -L $HOME/Work ]]; then
    shopt -s dotglob nullglob
    for e in "$HOME/Work"/*; do
        n=$(basename "$e")
        if [[ -e $HOME/Projetos/$n ]]; then echo "aviso: ~/Projetos/$n já existe; ~/Work mantida" >&2; exit 1; fi
    done
    for e in "$HOME/Work"/*; do mv "$e" "$HOME/Projetos/"; done
    rmdir "$HOME/Work"
fi
[[ -L $HOME/Work ]] && rm "$HOME/Work"

for d in Desktop Documents Downloads Music Pictures Public Templates Videos Projects \
    "Área de trabalho" Documentos Música Músicas Imagens Público Modelos Vídeos; do
    [[ -d $HOME/$d && ! -L $HOME/$d ]] || continue
    rmdir "$HOME/$d" 2>/dev/null && echo "removida ~/$d (vazia)" ||
        echo "aviso: ~/$d tem conteúdo; mova para a pasta PARA certa e apague à mão." >&2
done
echo "Home PARA: ~/Projetos ~/Áreas ~/Recursos ~/Arquivados"
