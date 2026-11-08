#!/usr/bin/env bash
# kitty-official.sh — instala/atualiza o kitty pelo instalador OFICIAL
# (https://sw.kovidgoyal.net/kitty/binary/) em ~/.local/kitty.app e o
# integra como terminal padrão do KDE Plasma 6 no Fedora.
#
# Idempotente: pode ser rodado várias vezes (também serve para atualizar).
# NÃO toca em ~/.config/kitty/kitty.conf (link do stow).
#
# Variáveis opcionais:
#   REMOVE_DNF_KITTY=yes|no  responde de antemão se remove o kitty do dnf

set -euo pipefail

# ---------------------------------------------------------------- utilitários
info()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()    { printf '\033[1;32m ok\033[0m %s\n' "$*"; }
warn()  { printf '\033[1;33m !!\033[0m %s\n' "$*" >&2; }
die()   { printf '\033[1;31mERRO\033[0m %s\n' "$*" >&2; exit 1; }
have()  { command -v "$1" >/dev/null 2>&1; }

ask_yes_no() { # $1 = pergunta; retorna 0 para sim. Padrão: não.
    local reply=""
    if [[ -t 0 ]]; then
        read -r -p "$1 [s/N] " reply || true
    else
        warn "Sem terminal interativo; assumindo 'não' para: $1"
    fi
    [[ "$reply" =~ ^[sSyY] ]]
}

[[ $EUID -ne 0 ]] || die "Rode como usuário normal (sem sudo). O script pede sudo só quando precisa."
have curl || die "curl não encontrado. Rode ./bootstrap/install.sh primeiro."

HOME_REAL="$(readlink -f "$HOME")"
APP_DIR="$HOME_REAL/.local/kitty.app"
BIN_DIR="$HOME_REAL/.local/bin"
APPS_DIR="$HOME_REAL/.local/share/applications"
KITTY_BIN="$APP_DIR/bin/kitty"
KITTEN_BIN="$APP_DIR/bin/kitten"
ICON="$APP_DIR/share/icons/hicolor/256x256/apps/kitty.png"
SVC_NAME="shortcut-kitty.service"
SVC_DST="$HOME_REAL/.config/systemd/user/$SVC_NAME"
BACKUP_DIR="$HOME_REAL/.local/state/kitty-official/backups"
STAMP="$(date +%Y%m%d-%H%M%S)"

# ---------------------------------------------------- 1. instalar / atualizar
info "1/5 Instalando/atualizando kitty oficial em $APP_DIR"
if [[ -x "$KITTY_BIN" ]]; then
    info "Versão atual: $("$KITTY_BIN" --version 2>/dev/null || echo desconhecida)"
fi
# O instalador oficial baixa a última versão e substitui ~/.local/kitty.app.
curl -fL https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin launch=n
[[ -x "$KITTY_BIN" ]] || die "Instalação falhou: $KITTY_BIN não existe."
ok "Instalado: $("$KITTY_BIN" --version)"

# ------------------------------------------- 2. links + integração desktop
info "2/5 Criando links em $BIN_DIR e arquivos .desktop em $APPS_DIR"
mkdir -p "$BIN_DIR" "$APPS_DIR"
ln -sfn "$KITTY_BIN"  "$BIN_DIR/kitty"
ln -sfn "$KITTEN_BIN" "$BIN_DIR/kitten"

for f in kitty.desktop kitty-open.desktop; do
    src="$APP_DIR/share/applications/$f"
    [[ -f "$src" ]] || { warn "$src não encontrado; pulando."; continue; }
    install -m 0644 "$src" "$APPS_DIR/$f"
    # Conforme a doc oficial: Icon e Exec com caminho absoluto (e TryExec também).
    sed -i \
        -e "s|^Icon=kitty\$|Icon=$ICON|" \
        -e "s|^TryExec=kitty\$|TryExec=$KITTY_BIN|" \
        -e "s|^Exec=kitty|Exec=$KITTY_BIN|" \
        "$APPS_DIR/$f"
done
ok "Arquivos .desktop instalados (sobrepõem os de /usr/share/applications)."

if have update-desktop-database; then
    update-desktop-database "$APPS_DIR" >/dev/null 2>&1 || warn "update-desktop-database falhou (não crítico)."
fi
if have kbuildsycoca6; then
    kbuildsycoca6 >/dev/null 2>&1 || warn "kbuildsycoca6 falhou (não crítico)."
fi

# --------------------------------------------------- 3. terminal padrão
info "3/5 Definindo kitty como terminal padrão"
if have kwriteconfig6; then
    kwriteconfig6 --file kdeglobals --group General --key TerminalApplication kitty
    kwriteconfig6 --file kdeglobals --group General --key TerminalService kitty.desktop
    ok "KDE: TerminalApplication=kitty, TerminalService=kitty.desktop"
else
    warn "kwriteconfig6 não encontrado; pulei a configuração do KDE."
fi

# xdg-terminal-exec
mkdir -p "$HOME_REAL/.config"
XDG_TERMS="$HOME_REAL/.config/xdg-terminals.list"
if [[ -f "$XDG_TERMS" ]] && [[ "$(head -n1 "$XDG_TERMS")" == "kitty.desktop" ]]; then
    ok "xdg-terminals.list já começa com kitty.desktop"
else
    if [[ -f "$XDG_TERMS" ]]; then
        mkdir -p "$BACKUP_DIR"
        cp -a "$XDG_TERMS" "$BACKUP_DIR/xdg-terminals.list.$STAMP"
        { echo "kitty.desktop"; grep -vx 'kitty.desktop' "$XDG_TERMS" || true; } > "$XDG_TERMS.tmp"
        mv "$XDG_TERMS.tmp" "$XDG_TERMS"
    else
        echo "kitty.desktop" > "$XDG_TERMS"
    fi
    ok "xdg-terminals.list atualizado"
fi

# ------------------------------------- 4. conflito com o kitty do dnf + service
info "4/5 Resolvendo conflito com o kitty do dnf e o $SVC_NAME"

# 4a. Unit do atalho Meta+T: plasma/apply.sh grava o kitty do PATH; aponte para o oficial.
if [[ -f "$SVC_DST" && ! -L "$SVC_DST" ]]; then
    if grep -q -- "-- $BIN_DIR/kitty\$" "$SVC_DST"; then
        ok "$SVC_DST já usa $BIN_DIR/kitty"
    else
        mkdir -p "$BACKUP_DIR"
        cp -a "$SVC_DST" "$BACKUP_DIR/$SVC_NAME.installed.$STAMP"
        sed -i "s#^\(ExecStart=.* -- \).*#\1$BIN_DIR/kitty#" "$SVC_DST"
        ok "$SVC_DST agora usa $BIN_DIR/kitty (backup em $BACKUP_DIR)"
        if have systemctl; then
            systemctl --user daemon-reload || warn "systemctl --user daemon-reload falhou."
        fi
    fi
else
    info "$SVC_DST ausente: plasma/apply.sh --apply a criará com o kitty do PATH."
fi

# 4b. Pacote do dnf
if rpm -q kitty >/dev/null 2>&1; then
    want="${REMOVE_DNF_KITTY:-ask}"
    if [[ "$want" == "yes" ]] || { [[ "$want" == "ask" ]] && ask_yes_no "Remover o pacote 'kitty' do dnf (/usr/bin/kitty)? O kitty oficial continuará funcionando."; }; then
        sudo dnf remove -y kitty
        ok "Pacote kitty do dnf removido."
    else
        warn "Mantendo o kitty do dnf. ~/.local/bin vem antes no PATH, e os .desktop de ~/.local têm prioridade; tudo usará o oficial."
    fi
else
    ok "Pacote kitty do dnf não está instalado."
fi

# ------------------------------------------------------------- 5. verificação
info "5/5 Verificação"
export PATH="$BIN_DIR:$PATH"
hash -r
echo "kitty --version:            $(kitty --version)"
echo "readlink -f \$(command -v kitty): $(readlink -f "$(command -v kitty)")"
if have kreadconfig6; then
    echo "TerminalService (KDE):      $(kreadconfig6 --file kdeglobals --group General --key TerminalService)"
    echo "TerminalApplication (KDE):  $(kreadconfig6 --file kdeglobals --group General --key TerminalApplication)"
fi
echo "xdg-terminals.list:         $(head -n1 "$XDG_TERMS")"
if [[ -f "$SVC_DST" ]]; then
    echo "--- ExecStart do $SVC_NAME ---"
    grep '^ExecStart=' "$SVC_DST" || true
fi
ok "Concluído. Faça logout/login (ou reinicie o Plasma) para o KDE reler o terminal padrão."
