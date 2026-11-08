#!/usr/bin/env bash
# Home no método PARA: só Projetos, Áreas, Recursos e Arquivados.
# As pastas pessoais padrão (Downloads, Imagens, Músicas, Vídeos...) ficam
# dentro de Recursos; a Área de trabalho e o Público ficam em Projetos e
# Documentos em Áreas/Documentos. Fora delas só existem as quatro pastas PARA.
# Pastas ocultas (.config, .local...) não são tocadas.
#
# Uso: ./bootstrap/para.sh   (idempotente; nunca move nem apaga conteúdo)
set -euo pipefail

cfg="${XDG_CONFIG_HOME:-$HOME/.config}"
mkdir -p "$cfg"
mkdir -p "$HOME"/{Projetos,Áreas,Recursos,Arquivados}
mkdir -p "$HOME/Projetos/Desktop"
mkdir -p "$HOME/Projetos/Público"
mkdir -p "$HOME/Áreas/Documentos"
mkdir -p "$HOME/Recursos"/{Downloads,Imagens,Músicas,Vídeos,Modelos}

cat >"$cfg/user-dirs.dirs" <<'EOF'
# Gerado por bootstrap/para.sh (método PARA).
XDG_DESKTOP_DIR="$HOME/Projetos/Desktop"
XDG_DOWNLOAD_DIR="$HOME/Recursos/Downloads"
XDG_DOCUMENTS_DIR="$HOME/Áreas/Documentos"
XDG_PROJECTS_DIR="$HOME/Projetos"
XDG_MUSIC_DIR="$HOME/Recursos/Músicas"
XDG_PICTURES_DIR="$HOME/Recursos/Imagens"
XDG_VIDEOS_DIR="$HOME/Recursos/Vídeos"
XDG_TEMPLATES_DIR="$HOME/Recursos/Modelos"
XDG_PUBLICSHARE_DIR="$HOME/Projetos/Público"
EOF
# Sem isto, o xdg-user-dirs-update do login recria as pastas padrão.
printf 'enabled=False\n' >"$cfg/user-dirs.conf"

# Capturas do Spectacle vão para a caixa de entrada (Downloads).
if command -v kwriteconfig6 >/dev/null; then
    kwriteconfig6 --file spectaclerc --group ImageSave --key imageSaveLocation "file://$HOME/Recursos/Downloads"
    kwriteconfig6 --file spectaclerc --group VideoSave --key videoSaveLocation "file://$HOME/Recursos/Downloads"
fi

# Nomes em inglês e em português, como o xdg-user-dirs cria em cada idioma.
for d in Desktop Documents Downloads Music Pictures Public Templates Videos \
    "Área de trabalho" Documentos Música Músicas Imagens Público Modelos Vídeos; do
    [[ -d $HOME/$d && ! -L $HOME/$d ]] || continue
    if rmdir "$HOME/$d" 2>/dev/null; then
        echo "  removida ~/$d (vazia)"
    else
        echo "aviso: ~/$d tem conteúdo; mova para a pasta PARA certa e apague à mão." >&2
    fi
done
echo "Home PARA: ~/Projetos ~/Áreas ~/Recursos ~/Arquivados"
