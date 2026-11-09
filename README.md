# Dotfiles — Omarchy

Configuração pessoal em cima do [Omarchy](https://omarchy.org) (Arch + Hyprland).
O Omarchy já cuida do tema, do tiling, das workspaces e do Neovim (LazyVim).
Aqui ficam só as diferenças que são minhas. Cada pasta é um pacote GNU Stow
para o `$HOME`.

## Estrutura

| Pasta | Conteúdo |
|---|---|
| `omarchy/hypr` | `bindings.lua` (atalhos), `input.lua` (layout por teclado), `workspaces.lua` (round robin entre monitores), `hyprland.lua` e `looknfeel.lua` (cursor Catppuccin) |
| `omarchy/kitty` | kitty com rastro do cursor; as cores seguem o tema do Omarchy |
| `omarchy/audio` | placa Intel com som do notebook e dos dois monitores (DisplayPort) ao mesmo tempo |
| `omarchy/xdg` | `user-dirs.dirs` no método PARA (e `user-dirs.conf` impedindo a recriação das pastas padrão) |
| `omarchy/hooks` | hook `theme-set` que aponta os fundos de todo tema para `~/Recursos/Imagens/Wallpapers` |
| `common/` | `zsh`, `starship`, `git`, `mise`: valem em qualquer distro |
| `legacy/fedora-kde/` | perfil antigo do Fedora KDE (Plasma, KWin, keyd, bootstrap dnf), mantido só como referência |

## Instalação

```sh
git clone git@github.com:jeffersonxc22/dotfiles.git ~/Projetos/dotfiles
~/Projetos/dotfiles/bootstrap-omarchy.sh
~/Projetos/dotfiles/para.sh
```

O bootstrap instala os pacotes (`omarchy pkg add` / `omarchy pkg aur add`),
define o kitty como terminal padrão e roda o `./deploy.sh`. O deploy move os
arquivos que estiverem no caminho para `~/.local/state/dotfiles/omarchy-<data>/`,
cria os links com o stow e valida o Hyprland com `hyprctl configerrors`.

## Atalhos próprios

| Tecla | Ação | Substitui o padrão do Omarchy |
|---|---|---|
| Super+T | terminal padrão (vira kitty quando ele for o padrão) | alternar flutuante (foi para **Super+Alt+T**) |
| Super+B | navegador padrão do Omarchy (Chromium) | — |
| Super+X | menu de sistema (sair, reiniciar, desligar) | recortar universal |
| Super+I | Claude Code (`omarchy-agent`) | alternar idioma de entrada |
| Super+S | print da tela | alternar scratchpad (foi para **Super+Shift+Alt+S**) |
| Super+E | gerenciador de arquivos (Nautilus) | — |
| Super+F | maximizar (mantém barra e gaps) | tela cheia (foi para **Super+Alt+F**) |

O resto já vem igual ao que eu usava no KDE: Super+1…0, Super+Shift+N (move e
segue), Super+Q, Super+Space (launcher). A lista completa está em
`omarchy menu keybindings --print` ou em Super+K.

## Workspaces

No lugar dos blocos de 1–10 por monitor do Omarchy, os workspaces são globais 1–10
e distribuídos em round robin da esquerda para a direita (`omarchy/hypr/.config/hypr/workspaces.lua`).
Com notebook | DP-1 | DP-3: notebook 1 4 7 10, DP-1 2 5 8, DP-3 3 6 9. Com menos monitores,
a conta se ajusta sozinha a cada reload.

## Home no método PARA

`./para.sh` organiza a home em `~/Projetos`, `~/Áreas`, `~/Recursos` e `~/Arquivados`:

| Pasta padrão | Vai para |
|---|---|
| Desktop, Público | `~/Projetos/Desktop`, `~/Projetos/Público` |
| Documentos | `~/Áreas/Documentos` |
| Downloads, Imagens, Músicas, Vídeos, Modelos | `~/Recursos/...` |
| `~/Work` (pasta de trabalho do Omarchy) | conteúdo em `~/Projetos`; `~/Work` deixa de existir e o `try` usa `~/Projetos/tries` |
| `~/dotfiles` | `~/Projetos/dotfiles` (o stow cria links relativos para lá) |

Prints vão para `~/Recursos/Imagens/Screenshots` e gravações para `~/Recursos/Vídeos`
(`OMARCHY_SCREENSHOT_DIR` e `OMARCHY_SCREENRECORD_DIR` no `hyprland.lua`).

## Áudio dos monitores

O perfil padrão da placa Intel só liga uma saída por vez: ou as caixas do notebook, ou o HDMI/DisplayPort.
`omarchy/audio` cria um perfil com as três juntas (notebook, monitor do meio e monitor da direita),
para elas aparecerem na troca de saída do Omarchy. A regra do WirePlumber aponta para o perfil por
caminho absoluto (`/home/jefferson/...`). Depois do deploy: `systemctl --user restart wireplumber`.

## Wallpapers (inclusive animados)

O Omarchy aceita imagem ou vídeo como fundo, sem plugin extra. Os wallpapers
ficam em `~/Recursos/Imagens/Wallpapers`, fora do git.

O seletor (**Super+Ctrl+Space**) lê `~/.config/omarchy/backgrounds/<tema>/`.
O hook `link-wallpapers` (`omarchy/hooks`) troca essa pasta por um link para
`~/Recursos/Imagens/Wallpapers`:

- O `deploy.sh` roda `link-wallpapers --all` para todos os temas instalados.
- A cada troca de tema, o hook cria o link do tema novo, se faltar.
- A pasta de um tema que já tenha arquivos próprios fica intacta.

Basta baixar o arquivo para a pasta (sem subpastas). Formatos aceitos: `jpg`,
`jpeg`, `png`, `gif`, `bmp`, `webp`, `mp4`, `m4v`, `mov`, `webm`, `mkv`, `avi`.
Para aplicar direto: `omarchy theme bg set ~/Recursos/Imagens/Wallpapers/arquivo.mp4`.
Na primeira vez em um tema novo, o fundo inicial é o padrão do tema.

## zsh

Segue o jeito oficial do Omarchy, com o pacote `omarchy-zsh`:

- O `omarchy-setup-zsh`, que o bootstrap roda uma vez, troca o `~/.bashrc` por um
  que faz `exec zsh` e copia o `~/.inputrc`. O shell de login continua bash
  (sem `chsh`), e o terminal abre direto no zsh.
- O `~/.zshrc` (`common/zsh/.zshrc`) é o template do Omarchy: carrega
  `/usr/share/omarchy-zsh/shell/{zoptions,all}`, com aliases, funções,
  mise, starship, zoxide, fzf e syntax-highlighting. As minhas personalizações
  ficam no fim: autosuggestions, ssh-agent, `BAT_THEME` Catppuccin,
  `~/.config/zsh/aliases.zsh` e `functions.zsh`.
- Para voltar ao bash: `sudo pacman -R omarchy-zsh` e restaurar o
  `~/.bashrc.backup-*`.

A versão antiga (com `ZDOTDIR`, do Fedora) está em `legacy/fedora-kde/zsh-zdotdir/`.
