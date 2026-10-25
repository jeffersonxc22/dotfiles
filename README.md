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
ryoku/.config/mise/config.toml        persona padrão (KODE_D_PERSONA)
ryoku/.config/opencode/opencode.json  instructions + skills do Kode-D Harness
```

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

```sh
# stow do pacote (do diretório deste repo)
stow --adopt -t "$HOME" ryoku

# o que não é dotfile
sudo ./root/apply.sh
```

`--adopt` move o arquivo vivo para dentro do repo antes de criar o symlink, então
o conteúdo local sempre ganha. Para desfazer: `stow -D -t "$HOME" ryoku`.

`~/.config/opencode/AGENTS.md` não é versionado: é gerado por
`ryoku-rashin wire opencode` e muda a cada reindex do Ryoku.

## O que NÃO está aqui

- Dotfiles do desktop em si (barra, tema, keybinds, monitores): o dono é o
  Ryoku, via `ryoku-shell`, `ryoku-hub` e `ryogami`. Ver a skill `ryoku`.
- Segredos, tokens, sessões e caches.
