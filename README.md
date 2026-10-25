# dotfiles

Configurações da máquina. Um pacote GNU Stow por frente.

```
ryoku/     o que é SEU no Ryoku Linux e sobrevive a `ryoku update`
legacy/    o que veio da máquina Ubuntu/niri e não se aplica aqui (histórico)
```

## ryoku/

Só caminhos que o Ryoku não sobrescreve. Tudo o que o `ryoku materialize`
reescreve (por exemplo `~/.config/fish/config.fish` ou `~/.config/nvim/`)
fica de fora: quando há uma mudança a fazer, ela vai para o override que o
`ryoku owner <path>` apontar.

```
ryoku/.config/fish/user.fish          override oficial do fish
ryoku/.config/fish/functions/         funções próprias
ryoku/.config/hypr/user.lua           overrides do Hyprland (carrega por último)
ryoku/.config/hypr/keyboard.lua       layout base dos teclados (seed do Ryoku)
ryoku/.config/herdr/config.toml       tema "terminal" = segue a paleta do Ryoku
ryoku/.config/mise/config.toml        persona padrão (KODE_D_PERSONA)
ryoku/.config/opencode/opencode.json  instructions + skills do Kode-D Harness
```

## Deploy

```sh
# stow do pacote (do diretório deste repo)
stow --adopt -t "$HOME" ryoku
```

`--adopt` move o arquivo vivo para dentro do repo antes de criar o symlink, então
o conteúdo local sempre ganha. Para desfazer: `stow -D -t "$HOME" ryoku`.

`~/.config/opencode/AGENTS.md` não é versionado: é gerado por
`ryoku-rashin wire opencode` e muda a cada reindex do Ryoku.

## O que NÃO está aqui

- Dotfiles do desktop em si (barra, tema, keybinds, monitores): o dono é o
  Ryoku, via `ryoku-shell`, `ryoku-hub` e `ryogami`. Ver a skill `ryoku`.
- Segredos, tokens, sessões e caches.
