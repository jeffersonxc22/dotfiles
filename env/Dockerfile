# kode-d — imagem base para os containers de projeto via Distrobox
#
# Responsabilidade ÚNICA deste arquivo: buildar a imagem e instalar os
# pacotes comuns a todos os ambientes. Não monta volumes nem conhece
# paths do host (ex: ~/dotfiles) — isso é feito na criação da instância
# (new-env.sh / distrobox.ini), não aqui.
#
# Base trocada de Arch para Ubuntu (necessário para instalar o Claude Desktop
# dentro do container e exportar pra máquina host via distrobox-export)

FROM ubuntu:26.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        wget \
        git \
        gnupg \
        locales \
        software-properties-common \
        sudo \
        unzip \
        zip \
        zsh \
        tmux \
        ripgrep \
        fd-find \
        fzf \
        bat \
        xclip \
        stow \
        neovim \
        pkg-config \
        libssl-dev \
        # dependências comuns pra Claude Desktop (Electron/AppImage/deb)
        libnss3 \
        libgtk-3-0 \
        libasound2t64 \
        libgbm1 \
        fuse \
    && locale-gen en_US.UTF-8 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Claude Desktop instalado direto na imagem base: assim TODO ambiente
# (cometa, e qualquer outro que vier) já nasce com o app disponível.
# Como cada ambiente tem home isolado (~/Envs/{nome}), o ~/.config/Claude
# de cada um fica separado — autenticação/sessão isolada por projeto,
# sem precisar de um container dedicado só pro Claude Desktop.
RUN curl -fsSLo /usr/share/keyrings/claude-desktop-archive-keyring.asc \
        https://downloads.claude.ai/claude-desktop/key.asc \
    && echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/claude-desktop-archive-keyring.asc] https://downloads.claude.ai/claude-desktop/apt/stable stable main" \
        > /etc/apt/sources.list.d/claude-desktop.list \
    && apt-get update && apt-get install -y --no-install-recommends claude-desktop \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Claude Code: pelo repositório apt oficial, não pelo instalador nativo
# (curl | bash) — esse instala em ~/.local/bin, por usuário, mesmo
# problema que tivemos com o mise. Via apt vira binário de sistema,
# funciona igual em qualquer home isolado sem reinstalar por ambiente.
RUN install -d -m 0755 /etc/apt/keyrings \
    && curl -fsSL https://downloads.claude.ai/keys/claude-code.asc \
        -o /etc/apt/keyrings/claude-code.asc \
    && echo "deb [signed-by=/etc/apt/keyrings/claude-code.asc] https://downloads.claude.ai/claude-code/apt/stable stable main" \
        > /etc/apt/sources.list.d/claude-code.list \
    && apt-get update && apt-get install -y --no-install-recommends claude-code \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Distrobox cria/mapeia o usuário do host automaticamente na primeira entrada;
# não criamos usuário aqui de propósito.

# Fonte pra Starship/terminal (opcional, ajuste se seu dotfiles já cuida disso)
RUN mkdir -p /usr/share/fonts/nerd-fonts

# Starship e mise: binários de sistema (/usr/local/bin), instalados aqui
# na imagem — não são "config de usuário", são pacotes como outro
# qualquer, então não pertencem ao bootstrap.sh.
RUN curl -sS https://starship.rs/install.sh | sh -s -- -y --bin-dir /usr/local/bin
RUN curl https://mise.run | MISE_INSTALL_PATH=/usr/local/bin/mise sh

# No Ubuntu/Debian o binário do pacote "bat" se chama "batcat" (conflito
# de nome com outro pacote já existente no repositório). Symlink pra
# poder chamar só "bat" normalmente — a alias cat=bat fica no seu
# zsh/.zshrc do dotfiles, não aqui (isso é config, não instalação).
RUN ln -sf /usr/bin/batcat /usr/local/bin/bat

# bat não vem com temas Catppuccin embutidos — baixa e registra no cache
# de sistema (/etc/bat), pra funcionar em qualquer ambiente/home isolado
# sem precisar refazer isso por container.
ENV BAT_CONFIG_DIR=/etc/bat
RUN mkdir -p /etc/bat/themes \
    && curl -fsSL -o "/etc/bat/themes/Catppuccin Mocha.tmTheme" \
        "https://github.com/catppuccin/bat/raw/main/themes/Catppuccin%20Mocha.tmTheme" \
    && bat cache --build

# Nenhum volume é declarado/montado aqui de propósito. O mount de
# ~/dotfiles (e outros volumes comuns) acontece na criação da instância,
# via `distrobox create --volume` (new-env.sh) ou `volume=` (distrobox.ini).

# Apps Electron dentro do container (Claude Desktop) chamam xdg-open pra
# abrir links (ex: login). O xdg-open do xdg-utils detecta o desktop via
# env herdada do host (aqui, KDE) e tenta chamar "kde-open", que não
# existe nesta imagem minimalista — e falha.
#
# Em vez de instalar um monte de pacote KDE só pra isso, sobrescrevemos
# o xdg-open do container pra sempre delegar direto pro xdg-open REAL do
# host, via distrobox-host-exec (ferramenta do próprio Distrobox feita
# pra isso). Fica agnóstico de qual DE o host roda (KDE, GNOME, Cosmic
# etc.) — sempre quem abre o link é o navegador do host de verdade.
RUN printf '#!/bin/sh\nexec distrobox-host-exec xdg-open "$@"\n' > /usr/local/bin/xdg-open \
    && chmod +x /usr/local/bin/xdg-open

# RTK (rtk-ai) — CLI proxy que reduz tokens de comandos de shell antes de
# chegarem no contexto do Claude Code. Binário Rust único, sem MCP server
# próprio de fato — se integra via hook no ~/.claude/settings.json
# (rtk init -g, roda no bootstrap.sh, não aqui). O instalador oficial
# também joga em ~/.local/bin por padrão — mesma armadilha do mise e do
# instalador nativo do Claude Code — então forçamos pra system-wide.
# Depende de ripgrep (rg), já instalado acima.
RUN RTK_INSTALL_DIR=/usr/local/bin sh -c "$(curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh)"

CMD ["/bin/bash"]
