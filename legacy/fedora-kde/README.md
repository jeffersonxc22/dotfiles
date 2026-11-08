# Dotfiles — Fedora KDE

Configuração para Fedora com KDE Plasma 6: zsh, LazyVim, kitty, Starship, mise e Herdr.
Cada diretório de configuração é um pacote GNU Stow; arquivos do KDE não são
stowados. O histórico está na tag `pre-fedora-reorg`; o arquivo local
`archive/pre-fedora-reorg.tar.gz` não é publicado, pois inclui estado de sessão
e histórico de terminal.

## Estado da implementação

A sessão atual usa Layan Dark, Krohnkite e Geometry Change. O perfil do Plasma
está documentado em [plasma/README.md](plasma/README.md); a aplicação em uma
instalação nova ainda precisa ser validada. A configuração anterior do mise foi preservada em
`~/.config/mise/config.toml.pre-dotfiles-20261101125604` e os links foram
implantados. O pacote `zsh` instala `~/.zshenv`, que define `ZDOTDIR` como
`~/.config/zsh`; a configuração interativa fica em `~/.config/zsh/.zshrc`.
O `~/.zshrc` que já exista não é usado quando esse `ZDOTDIR` está ativo e não
é substituído pelo deploy. Caso exista um `~/.zshenv` anterior, faça backup e
resolva o conflito antes de executar o Stow; o deploy não usa `--adopt`.

## Estrutura

| Pasta | Conteúdo |
|---|---|
| `zsh/ nvim/ kitty/ starship/ git/ mise/ fontconfig/` | pacotes Stow para `$HOME` |
| `keyd/` | pacote Stow para `/etc` (ver `keyd/README.md`) |
| `plasma/` | perfil KDE: `prereqs.sh`, `theme.sh`, `apply.sh` |
| `theme/` | GTK, kitty, Flatpak, cursor e tela de login |
| `bootstrap/` | `install.sh` (orquestra tudo, com a interface de `ui.sh`), `packages.txt`, `drivers.sh`, `nvidia-container-toolkit.sh`, `kitty-official.sh`, `keyd.sh`, `para.sh`, `verify.sh` |

Para adicionar um pacote, acrescente uma linha em `bootstrap/packages.txt`.

## Guia de instalação (Fedora KDE do zero)

### 1. Antes de começar
- Instale o **Fedora KDE Plasma Desktop** (ISO em https://fedoraproject.org/kde/)
  e faça o primeiro login. O script precisa da sessão Plasma ativa.
- Conecte-se à internet. Se a máquina tiver GPU NVIDIA, **desative o Secure
  Boot** na BIOS ou planeje assinar o módulo: com ele ativo, o driver é pulado.
- Tenha a senha do seu usuário à mão: o sudo pode pedir mais de uma vez.

### 2. Baixar e rodar
Abra o Konsole e rode:

```sh
sudo dnf install -y git
git clone https://github.com/jeffersonxc22/dotfiles.git ~/.dotfiles && cd ~/.dotfiles
./bootstrap/install.sh
```

A tela mostra a barra de progresso, a etapa atual e o tempo de cada uma, além
da saída real dos comandos. O script só para para perguntar duas coisas: a
senha do sudo e se você quer instalar o driver NVIDIA.

### 3. O que cada etapa faz
Tudo é instalado pela forma oficial: pacote do Fedora, repositório do
fabricante ou, quando não há rpm, o instalador do próprio projeto.

| # | Etapa | Detalhe |
|---|---|---|
| 1 | dnf paralelo | `max_parallel_downloads=20` |
| 2 | Atualização | `dnf upgrade --refresh` |
| 3 | Sistema | RPM Fusion, openh264, ffmpeg completo, `@multimedia`, vídeo Intel, `akmod-nvidia` (open) com confirmação |
| 4 | Pacotes | `bootstrap/packages.txt`: zsh, zoxide, fzf, eza, stow, neovim, bat, ripgrep, fd, podman… |
| 5 | NVIDIA/Podman | NVIDIA Container Toolkit pelo repositório oficial e CDI (`nvidia.com/gpu=all`); só roda se houver GPU e driver NVIDIA |
| 6 | mise e starship | mise pelo COPR oficial `jdxcode/mise`; starship pelo instalador oficial |
| 7 | Shell | zsh como shell padrão |
| 8 | Plugins zsh | autosuggestions, syntax-highlighting, fzf-tab, completions e tema do bat |
| 9 | Dotfiles | `./deploy.sh`: stow sem `--adopt` (para em conflito) |
| 10 | Ferramentas | `mise install`: go, node 24, python 3, java, rust, gcloud, usage, maven |
| 11 | Terminal | kitty oficial como terminal padrão, com cores seguindo o KDE |
| 12 | Tema | Layan + Catppuccin Mocha Sapphire, Slot Icons com bandeja Papirus, cursor Catppuccin, GTK, Flatpak, fundo sólido `#1e1e2e` na área de trabalho e no bloqueio |
| 13 | Login | Plasma Login Manager com o mesmo esquema, fontes, ícones e cursor |
| 14 | Programas | Google Chrome (navegador padrão), Slack (.rpm oficial), Claude Code (repositório dnf oficial) |
| 15 | Plasma | keyd (teclados Logitech), 10 áreas de trabalho, tiling Krohnkite, atalhos do KWin, efeitos e painel |
| 16 | Home PARA | só `Projetos`, `Áreas`, `Recursos`, `Arquivados`; Desktop e Público em `~/Projetos`, Documentos em `~/Áreas/Documentos` e Downloads/Imagens/Músicas/Vídeos/Modelos em `~/Recursos` |
| 17 | Conferência | `bootstrap/verify.sh`, com o resultado em `bootstrap/verify.log` |

### 4. Se algo falhar
O script para e mostra a etapa que falhou e o código de erro. Corrija o que a
mensagem acima do quadro indicar e rode `./bootstrap/install.sh` de novo: as
etapas já feitas são puladas. Casos comuns:
- **Conflito no stow (etapa 9):** já existe um arquivo no lugar do link, por
  exemplo `~/.zshenv`. Faça backup, remova o arquivo e rode de novo.
- **Slack não encontrado:** a página da Slack mudou. Baixe o .rpm em
  https://slack.com/downloads/linux e rode `sudo dnf install ./slack-*.rpm`.

### 5. Depois de terminar
1. **Reinicie**: vale o zsh, o kernel novo e, se instalado, o driver NVIDIA.
   No caso do NVIDIA, espere `modinfo -F version nvidia` mostrar a versão
   antes de reiniciar.
2. Confira `bootstrap/verify.log`: o ideal é 0 FAIL.
3. **Fundo do login** (ainda manual): Configurações do Sistema > Tela de Login
   > papel de parede *Cor sólida* `#1e1e2e`.
4. Ative o keyd (o install só cria o link, de propósito): `sudo systemctl enable --now keyd`.
5. Coloque o vault do Hivemind em `~/Áreas/Documentos/hivemind` (`gh repo clone jeffersonxc22/hivemind ~/Áreas/Documentos/hivemind`).
6. Para atualizar o kitty ou o Slack no futuro, rode o script de novo, ou só
   `./bootstrap/kitty-official.sh`.

O Neovim usa Catppuccin e tenta acompanhar as cores de `kdeglobals`; sem cores
válidas usa Mocha. O kitty recebe cores do KDE por um serviço de usuário e usa
paletas ANSI Catppuccin. Aplicativos Flatpak e libadwaita podem não respeitar
todos os aspectos do tema do host.

## NVIDIA Container Toolkit + Podman

A etapa 5 instala o `nvidia-container-toolkit` pelo repositório oficial da NVIDIA
e configura o Podman via CDI, o modo recomendado pela NVIDIA: não usa o hook OCI
do Docker e funciona também com Podman rootless. O serviço `nvidia-cdi-refresh`
mantém `/var/run/cdi/nvidia.yaml` atualizado a cada boot e atualização do driver.

Para rodar um contêiner com todas as GPUs:

```sh
podman run --rm --device nvidia.com/gpu=all --security-opt=label=disable \
  docker.io/library/ubuntu:24.04 nvidia-smi -L
```

`--security-opt=label=disable` é necessário no Fedora com SELinux para o
contêiner acessar os dispositivos e as bibliotecas do driver. O dotfiles já
define a função `podman-gpu`, que inclui as duas opções:

```sh
podman-gpu docker.io/library/ubuntu:24.04 nvidia-smi -L
```

Para listar os dispositivos CDI disponíveis:

```sh
nvidia-ctk cdi list
```

Se o dispositivo sumir depois de atualizar o driver ou o toolkit, regenere a
especificação:

```sh
sudo systemctl restart nvidia-cdi-refresh.service
```

O `./bootstrap/verify.sh` confere o binário, o pacote, a especificação CDI e o
serviço quando o driver NVIDIA está carregado.

## Upgrade do Fedora

`./bootstrap/fedora-upgrade.sh --check` mostra a próxima versão, calculada a
partir de `rpm -E %fedora`. Sem `--check`, o script atualiza pacotes, baixa a
próxima versão e pergunta antes de reiniciar. Verifique antes se ela foi lançada
 e faça backup; não é necessário atualizar o Fedora 44 agora.
