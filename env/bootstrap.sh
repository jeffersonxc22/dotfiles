#!/usr/bin/env bash
# bootstrap.sh — provisiona um container recém-criado (kode-d / Ubuntu)
# Rodar DENTRO do container: distrobox enter <env> -- bash ~/dotfiles/env/bootstrap.sh
#
# IMPORTANTE: $HOME dentro do container é o home ISOLADO do ambiente
# (ex: /home/jefferson/Envs/nemu) — não é o /home/jefferson real. O repo
# de dotfiles é compartilhado entre ambientes via volume, montado em
# /home/${DOTFILES_USER}/dotfiles (path fixo do host, igual em todo
# ambiente), então NUNCA usamos "$HOME/dotfiles" aqui — só o path fixo.

set -euo pipefail

DOTFILES_USER="${DOTFILES_USER:-$(id -un)}"
DOTFILES_DIR="/home/${DOTFILES_USER}/dotfiles"
ENV_NAME="$(basename "$HOME")"

log() { printf '\n\033[1;36m==> %s\033[0m\n' "$1"; }

if [ ! -d "$DOTFILES_DIR" ]; then
    echo "Erro: $DOTFILES_DIR não existe. O volume dos dotfiles não foi"
    echo "montado — confira o 'volume=' no distrobox.ini pra este ambiente."
    exit 1
fi

# 1. zsh como shell padrão
log "Configurando zsh como shell padrão"
if [ "$SHELL" != "$(command -v zsh)" ]; then
    sudo chsh -s "$(command -v zsh)" "$USER"
fi

# 2. Oh My Zsh (precisa vir ANTES do stow, senão sobrescreve o .zshrc linkado).
# Fica aqui, e não no Dockerfile, porque instala em $HOME (~/.oh-my-zsh) —
# que é isolado por ambiente. Não é "pacote de sistema", é config de usuário.
log "Instalando Oh My Zsh"
if [ ! -d "${HOME}/.oh-my-zsh" ]; then
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# 3. Stow — agora sim, depois do Oh My Zsh já ter criado os arquivos base.
# Usa o dotfiles montado por volume, não um clone dentro do home isolado.
#
# O Oh My Zsh cria um ~/.zshrc de verdade (arquivo, não symlink) — e o
# Stow recusa sobrescrever arquivo real por padrão. Por isso removemos
# esse arquivo (e outros candidatos comuns a conflito) ANTES de stowar,
# guardando backup. Sem isso, o Stow falhava e o "|| fallback" antigo
# engolia o erro silenciosamente sem linkar nada.
log "Removendo arquivos gerados que vão conflitar com o Stow"
for f in .zshrc .bashrc .profile .gitconfig; do
    if [ -f "${HOME}/${f}" ] && [ ! -L "${HOME}/${f}" ]; then
        mv "${HOME}/${f}" "${HOME}/${f}.pre-stow.bak"
        echo "  ${f} -> ${f}.pre-stow.bak"
    fi
done

log "Aplicando dotfiles com GNU Stow"
cd "$DOTFILES_DIR"

# Garante que os submodules (ex: config do nvim) estão inicializados —
# senão o Stow linka pra uma pasta vazia
if [ -f .gitmodules ]; then
    git submodule update --init --recursive
fi

# Sem supressão de erro: se algo ainda conflitar, queremos VER a
# mensagem do Stow, não mascarar com um fallback que não faz nada.
#
# "env/" fica de fora do Stow de propósito: é a pasta dos scripts de
# infraestrutura (Dockerfile, bootstrap.sh, new-env.sh, distrobox.ini),
# não são "dotfiles" pra virar link solto na raiz do $HOME. Fica
# acessível só via ~/dotfiles/env/.
STOW_PACKAGES=()
for pkg in */; do
    pkg="${pkg%/}"
    [ "$pkg" = "env" ] && continue
    STOW_PACKAGES+=("$pkg")
done
stow -v -t "$HOME" "${STOW_PACKAGES[@]}"

# 4. Identidade Git — de propósito NÃO vem do dotfiles/Stow. Se viesse,
# seria um symlink pro MESMO arquivo compartilhado entre todos os
# ambientes (o volume é um só), e configurar um ambiente mudaria a
# identidade dos outros também. Aqui é sempre "git config --global",
# que escreve direto no $HOME isolado deste container — cada ambiente
# guarda sua própria identidade, de verdade isolada.
log "Configurando identidade Git deste ambiente"
if ! git config --global user.email >/dev/null 2>&1; then
    read -rp "Nome pro git (user.name) deste ambiente [$ENV_NAME]: " GIT_NAME
    read -rp "Email pro git (user.email) deste ambiente: " GIT_EMAIL
    git config --global user.name "${GIT_NAME:-$ENV_NAME}"
    git config --global user.email "$GIT_EMAIL"
else
    echo "Já configurado: $(git config --global user.name) <$(git config --global user.email)>"
fi

# 5. Tokens de MCP servers — de propósito NÃO vão pro dotfiles (mesmo
# raciocínio da identidade Git: são segredo e específicos por ambiente).
# Ficam num arquivo isolado, fora do Stow, que o .zshrc (stowado) carrega
# via source. Os configs compartilhados (.mcp.json / claude_desktop_config.json)
# só referenciam ${NOME_DA_VAR} — nunca o valor literal.
#
# Uso: chame set_mcp_env_var "NOME_DA_VAR" pra cada token que um MCP
# server precisar, conforme for adicionando eles (ex: abaixo, comentado).
MCP_ENV_FILE="${HOME}/.config/claude-mcp.env"
mkdir -p "$(dirname "$MCP_ENV_FILE")"
touch "$MCP_ENV_FILE"
chmod 600 "$MCP_ENV_FILE"

set_mcp_env_var() {
    local var_name="$1"
    if ! grep -q "^export ${var_name}=" "$MCP_ENV_FILE" 2>/dev/null; then
        read -rsp "Valor pra ${var_name} (Enter pra pular): " value
        echo
        if [ -n "$value" ]; then
            echo "export ${var_name}=\"${value}\"" >> "$MCP_ENV_FILE"
        fi
    fi
}

log "Configurando MCP servers deste ambiente"

# Só context-mode e RTK — GitHub/Context7/Google Drive ficam de fora:
# Google Drive já vem herdado da conta Claude nativa, e os outros dois
# saíram por decisão do usuário. Nenhum dos dois que sobrou usa token
# (context-mode é local; RTK nem é MCP server de verdade, é hook).

if command -v claude >/dev/null 2>&1; then
    # context-mode — plugin completo (marketplace + install), em vez do
    # MCP-only anterior. Isso registra os hooks automáticos (PreToolUse,
    # PostToolUse, SessionStart etc.) e o roteamento automático — sem
    # isso, o modelo só *pode* usar as ctx_* tools, mas não é nudged a
    # preferir elas sobre Bash/Read cru (é o que o MCP-only entregava).
    # Sem token, sem login — o marketplace é um repo GitHub público
    # clonado via HTTPS.
    #
    # Sem guard manual de idempotência: testado rodando os dois comandos
    # duas vezes seguidas — ambos já são idempotentes nativamente
    # ("already on disk" / "already installed", exit 0), então uma
    # checagem própria em cima disso seria redundante.
    claude plugin marketplace add mksglu/context-mode
    claude plugin install context-mode@context-mode

    # superpowers (github.com/obra/superpowers) — metodologia de
    # desenvolvimento (spec -> plano -> subagent-driven TDD). Mesmo
    # padrão do context-mode: marketplace + install, sem token, sem
    # login, idempotente. Testado que registra SÓ um hook de
    # SessionStart — nenhum PreToolUse/Bash, então não entra na mesma
    # disputa de hook que context-mode/rtk (ver nota do vault
    # validate-context-mode-rtk-compatibility).
    #
    # NOTA: o marketplace "oficial" da Anthropic (`/plugin install
    # superpowers@claude-plugins-official`, mencionado no README) não
    # funcionou no CLI headless testado aqui (marketplace não populado
    # sem sessão real/autenticada). Usando o marketplace GitHub do
    # próprio projeto (obra/superpowers-marketplace), que testei
    # funcionando sem conta.
    claude plugin marketplace add obra/superpowers-marketplace
    claude plugin install superpowers@superpowers-marketplace
fi

# RTK — registra o hook no Claude Code (escreve em ~/.claude/settings.json,
# que é STOWED/compartilhado — de propósito, já que não é segredo, é só
# um hook igual em todo ambiente). Sem token, sem MCP server de verdade.
#
# --auto-patch é OBRIGATÓRIO aqui: testado sem ele, em modo não-interativo
# (exatamente o contexto deste script), `rtk init -g` NÃO escreve o hook —
# ele pergunta "Patch existing settings.json? [y/N]", assume N por padrão,
# imprime um "MANUAL STEP" com o JSON pra você colar à mão, e ainda assim
# sai com exit 0. Ou seja: sem essa flag, o bootstrap "funcionaria" sem
# erro nenhum e o hook simplesmente nunca seria instalado.
#
# Testado também: com --auto-patch, o merge preserva outras chaves do
# settings.json (ex: enabledPlugins do context-mode) e faz backup
# automático (settings.json.bak). Rodar duas vezes é idempotente —
# "hook already present" na segunda chamada, sem duplicar.
if command -v rtk >/dev/null 2>&1 && command -v claude >/dev/null 2>&1; then
    rtk init -g --auto-patch
fi

# 6. Exporta o Claude Desktop deste ambiente pro launcher do host, com
# nome padronizado "claude-{env}" (ex: claude-nemu, claude-cometa) via
# --export-label, pra distinguir no launcher qual ambiente cada ícone abre.
log "Exportando Claude Desktop deste ambiente pro host (claude-${ENV_NAME})"
if command -v claude-desktop >/dev/null 2>&1; then
    distrobox-export --app claude-desktop --export-label "${ENV_NAME}"
fi

log "Bootstrap concluído. Abra um novo shell (zsh) para aplicar tudo."
