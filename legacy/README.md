# legacy

Configurações da máquina anterior (Ubuntu + kernel snap + niri/DankMaterialShell).
Ficam aqui como histórico e referência; não são instaladas.

| Pacote | Por que não se aplica ao Ryoku |
|---|---|
| `install/` | `nvidia-after-kernel-update.sh` usa `apt`/`pc-kernel`/módulos assinados pela Canonical. No Arch quem cuida disso é o `pacman` mais o `ryoku-nvidia.hook`. Os outros dois scripts são de VA-API e de plugins do zsh no Ubuntu. |
| `ghostty/` | Ghostty não está instalado; o terminal do Ryoku é o kitty, já tematizado pelo `ryogami`. |
| `systemd/` | `dms-ghostty-colors.*` pertence ao DankMaterialShell (niri), que não roda aqui. |
| `herdr/` | Config antiga do Herdr. A atual vive em `ryoku/.config/herdr/config.toml` com `theme.name = "terminal"`. |
| `fish/` | O `config.fish` do Ryoku já cobre zoxide, mise, fzf, starship e eza. O que valia a pena foi colhido para `ryoku/.config/fish/`. Havia caminho fixo `/home/jefferson-xenofonte/...` e gambiarra de `batcat`. |
| `zsh/` | Redundante: o shell padrão é fish. |
| `nvim/` | É o nvim do Ryoku mais Catppuccin Mocha+teal. A máquina atual fica no tema do Ryoku (tokyonight + paleta do wallpaper), sem fork. |
| `mise/` | Mesmo conteúdo, agora em `ryoku/.config/mise/config.toml`. |
