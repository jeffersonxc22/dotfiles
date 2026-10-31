# dotfiles

Configurações da máquina. Um pacote GNU Stow por frente.

```
ryoku/     o que é SEU no Ryoku Linux e sobrevive a `ryoku update`
root/      o que a hibernação precisa em /etc (não é stow: rodar com sudo)
legacy/    o que veio da máquina Ubuntu/niri e não se aplica aqui (histórico)
```

## ryoku/

Só caminhos que o Ryoku não sobrescreve. Tudo o que o `ryoku materialize`
reescreve (por exemplo `~/.config/fish/config.fish` ou `~/.config/nvim/`)
fica de fora: quando há uma mudança a fazer, ela vai para o override que o
`ryoku owner <path>` apontar.

```
ryoku/.gitconfig                      identidade + helpers do `gh` (sem segredo)
ryoku/.config/fish/user.fish          override oficial do fish
ryoku/.config/fish/functions/         funções próprias
ryoku/.config/hypr/user.lua           overrides do Hyprland (carrega por último)
ryoku/.config/hypr/keyboard.lua       layout base dos teclados (seed do Ryoku)
ryoku/.config/herdr/config.toml       tema "terminal" = segue a paleta do Ryoku
ryoku/.config/mise/config.toml        contas do Kode-D (CLAUDE_CONFIG_DIR, CODEX_HOME)
ryoku/.config/opencode/opencode.json  instructions + skills + MCP do context-mode
```

### Contas dos agentes

O `mise` é a fonte única das variáveis. O global define a conta padrão; um
`.mise.toml` na raiz do projeto troca a conta daquela pasta e dos subdiretórios.

```
~/.local/share/kode-d/claude/<conta>/   CLAUDE_CONFIG_DIR (Claude Code)
~/.local/share/kode-d/codex/<conta>/    CODEX_HOME (Codex CLI)
~/.local/share/kode-d/RTK.md            instruções compartilhadas do rtk
~/.local/share/kode-d/vendor/           skills upstream (Obsidian)
```

- O estado (auth, sessões, plugins, caches) fica fora deste repositório.
- Este repositório guarda só o mapa de variáveis e a receita de instalação:
  `~/Projetos/IA/kode-d-harness/INSTALL.md`.
- O `mise` avalia o config global antes do projeto, então o `.mise.toml` do
  projeto repete os caminhos derivados; trocar só a conta não basta.

## root/

Arquivos de root que fazem a hibernação funcionar. Não entram por `stow`; são
aplicados por um script idempotente:

```sh
sudo ./root/apply.sh
```

```
root/etc/polkit-1/rules.d/49-ryoku-hibernate.rules  libera só hibernate-ignore-inhibit
root/apply.sh                                       aplica, reconstrói a UKI e confere
```

O detalhe do "por quê" (inhibitor do `ryoku-shell`, `resume failed (-5)` da
NVIDIA no initramfs) está em `root/README.md`. Há uma checagem que vale rodar
depois de update de kernel ou de driver:

```sh
lsinitcpio /boot/EFI/Linux/ryoku_linux.efi | grep -c extramodules/nvidia   # deve dar 0
```

## Deploy

Numa máquina em que os arquivos ainda não existem:

```sh
stow -t "$HOME" ryoku
```

Numa máquina que já tem Ryoku, `~/.config` está preenchido e o `stow` recusa.
Adote (o arquivo vivo entra no repo), revise o diff e, se o repo é a fonte da
verdade, restaure o repo — os symlinks já apontam para ele:

```sh
stow --adopt -t "$HOME" ryoku
git diff
git checkout -- ryoku
```

`--adopt` faz o conteúdo vivo ganhar. Num install novo isso importaria os
defaults do Ryoku por cima do repo; por isso o `git diff` é obrigatório.

O que não é dotfile (só no Arch):

```sh
sudo ./root/apply.sh
```

Para desfazer: `stow -D -t "$HOME" ryoku`.

`opencode.json` é cópia de referência: o OpenCode reescreve o arquivo vivo, então
ele não fica stowado — compare os dois antes de copiar.

`~/.config/opencode/AGENTS.md` não é versionado: é gerado por
`ryoku-rashin wire opencode` e muda a cada reindex do Ryoku.

## Fedora

O `ryoku/` é o mesmo pacote: no Fedora 44/45 o Ryoku usa os mesmos caminhos em
`~/.config`. Use um Fedora mutável (Workstation, KDE, Server ou spin; Atomic/
rpm-ostree não é suportado) e rode o instalador oficial uma vez:

```sh
sudo dnf5 upgrade --refresh
sudo dnf5 install curl
curl -fsSL https://raw.githubusercontent.com/Ryoku-dev/ryoku/main/ryoku-shell-installer/install.sh | bash
```

O instalador mantém o bootloader do Fedora e deixa a NVIDIA no nouveau. O pacote
`root/` **não** se aplica lá (ver `root/README.md`).

## O que NÃO está aqui

- Dotfiles do desktop em si (barra, tema, keybinds, monitores): o dono é o
  Ryoku, via `ryoku-shell`, `ryoku-hub` e `ryogami`. Ver a skill `ryoku`.
- Segredos, tokens, sessões e caches.
