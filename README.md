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
| `zsh/ nvim/ kitty/ starship/ git/ mise/ herdr/ fontconfig/` | pacotes Stow para `$HOME` |
| `keyd/` | pacote Stow para `/etc` (ver `keyd/README.md`) |
| `plasma/` | perfil KDE: `prereqs.sh`, `theme.sh`, `apply.sh` |
| `theme/` | GTK, kitty, Flatpak, cursor e tela de login |
| `bootstrap/` | `install.sh` (orquestra tudo), `packages.txt`, `drivers.sh`, `kitty-official.sh`, `keyd.sh`, `para.sh`, `verify.sh` |

Para adicionar um pacote, acrescente uma linha em `bootstrap/packages.txt`.

## Instalação

Num Fedora KDE novo, logado na sessão Plasma:

```sh
sudo dnf install -y git
git clone https://github.com/jeffersonxc22/dotfiles.git ~/dotfiles && cd ~/dotfiles
./bootstrap/install.sh
```

O `install.sh` executa, nesta ordem, sempre pela forma oficial (pacote do
Fedora, repositório do fabricante ou instalador do projeto quando não há rpm):

1. dnf com `max_parallel_downloads=20`.
2. `dnf upgrade --refresh`.
3. RPM Fusion e openh264; `bootstrap/drivers.sh` (ffmpeg completo,
   `@multimedia`, vídeo Intel e, com confirmação, `akmod-nvidia` open).
4. Pacotes de `bootstrap/packages.txt` (zsh, zoxide, fzf, eza, stow, neovim…).
5. mise (COPR oficial `jdxcode/mise`) e starship (instalador oficial).
6. zsh como shell padrão.
7. Plugins zsh e tema do bat.
8. `./deploy.sh`: stow dos pacotes (para em conflito; nunca usa `--adopt`).
9. `mise install` (go, node 24, python 3, java, rust, gcloud, usage, maven, herdr).
10. kitty oficial como terminal padrão, com cores seguindo o KDE.
11. `plasma/prereqs.sh` (Layan, Krohnkite, Geometry Change) e `plasma/theme.sh`
    (Layan + Catppuccin Mocha Sapphire, Slot Icons com bandeja Papirus, cursor
    Catppuccin, GTK, Flatpak, fundo sólido `#1e1e2e` na área de trabalho e no bloqueio).
12. `sudo theme/greeter.sh`: tela de login com o mesmo visual.
13. Google Chrome (navegador padrão), Slack (.rpm oficial) e Claude Code
    (repositório dnf oficial).
14. `bootstrap/keyd.sh` (keyd compilado da tag oficial + `keyd/logitech.conf`) e
    `plasma/apply.sh --apply`: 10 áreas de trabalho, tiling Krohnkite, atalhos
    do KWin, efeitos e painel.
15. `bootstrap/para.sh`: home só com Projetos, Areas, Recursos e Arquivados
    (Downloads em `~/Recursos/Downloads`).
16. `bootstrap/verify.sh`: resultado em `bootstrap/verify.log`.

Rodar de novo é seguro: cada etapa pula o que já está feito. Reinicie ao final.

O Neovim usa Catppuccin e tenta acompanhar as cores de `kdeglobals`; sem cores
válidas usa Mocha. O kitty recebe cores do KDE por um serviço de usuário e usa
paletas ANSI Catppuccin. Aplicativos Flatpak e libadwaita podem não respeitar
todos os aspectos do tema do host.

## Upgrade do Fedora

`./bootstrap/fedora-upgrade.sh --check` mostra a próxima versão, calculada a
partir de `rpm -E %fedora`. Sem `--check`, o script atualiza pacotes, baixa a
próxima versão e pergunta antes de reiniciar. Verifique antes se ela foi lançada
 e faça backup; não é necessário atualizar o Fedora 44 agora.
