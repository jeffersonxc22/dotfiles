#!/usr/bin/env bash
# Home no método PARA: só Projetos, Areas, Recursos e Arquivados.
# Downloads e a pasta da área de trabalho ficam dentro de Recursos; as pastas
# padrão (Documentos, Imagens, Vídeos...) deixam de existir. Pastas ocultas
# (.config, .local...) não são tocadas.
#
# Uso: ./bootstrap/para.sh   (idempotente; nunca move nem apaga conteúdo)
set -euo pipefail

cfg="${XDG_CONFIG_HOME:-$HOME/.config}"
mkdir -p "$cfg" "$HOME"/{Projetos,Areas,Arquivados} "$HOME/Recursos"/{Downloads,Desktop}

# "$HOME/" desativa o diretório, pela especificação xdg-user-dirs.
cat >"$cfg/user-dirs.dirs" <<'EOF'
# Gerado por bootstrap/para.sh (método PARA).
XDG_DESKTOP_DIR="$HOME/Recursos/Desktop"
XDG_DOWNLOAD_DIR="$HOME/Recursos/Downloads"
XDG_TEMPLATES_DIR="$HOME/"
XDG_PUBLICSHARE_DIR="$HOME/"
XDG_DOCUMENTS_DIR="$HOME/"
XDG_MUSIC_DIR="$HOME/"
XDG_PICTURES_DIR="$HOME/"
XDG_VIDEOS_DIR="$HOME/"
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
    "Área de trabalho" Documentos Música Imagens Público Modelos Vídeos; do
    [[ -d $HOME/$d && ! -L $HOME/$d ]] || continue
    if rmdir "$HOME/$d" 2>/dev/null; then
        echo "  removida ~/$d (vazia)"
    else
        echo "aviso: ~/$d tem conteúdo; mova para a pasta PARA certa e apague à mão." >&2
    fi
done
echo "Home PARA: ~/Projetos ~/Areas ~/Recursos ~/Arquivados"
