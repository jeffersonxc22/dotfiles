# Dotfiles — Fedora KDE

Configuração para Fedora KDE: zsh, LazyVim, kitty, Starship, mise e Herdr.
Cada diretório de configuração é um pacote GNU Stow; arquivos do KDE não são
stowados. O histórico está na tag `pre-fedora-reorg`; o arquivo local
`archive/pre-fedora-reorg.tar.gz` não é publicado, pois inclui estado de sessão
e histórico de terminal.

## Estado da implementação

A sessão atual usa Layan Dark, Krohnkite e Geometry Change. O perfil do Plasma
está documentado em [plasma/README.md](plasma/README.md); a aplicação em uma
instalação nova ainda precisa ser validada. A configuração anterior do mise foi preservada em
`~/.config/mise/config.toml.pre-dotfiles-20261101125604` e os links foram
implantados. O arquivo `~/.zshrc` existente também permanece intacto;
o zsh passará a usar o `ZDOTDIR` definido em `~/.zshenv`.

## Instalação

1. Revise `bootstrap/packages.txt` e rode `./bootstrap/install.sh` (solicita sudo).
2. Resolva os conflitos existentes e rode `./deploy.sh`. O script usa
   `stow --no-folding`, com simulação prévia, sem `--adopt`.
3. Para o perfil atual de espaços, painel e atalhos, consulte
   [plasma/README.md](plasma/README.md) e, após instalar os pré-requisitos,
   rode `./plasma/apply.sh --apply` dentro da sessão Plasma. A instalação
   completa do Layan ainda não é automatizada.
4. Opcional: `sudo ./theme/greeter.sh layan` configura o Plasma Login Manager
   após instalar o esquema Layan e Future Cursors. Não é configuração do SDDM;
   a aparência deve ser verificada no próximo login.
5. `mise install` instala as ferramentas configuradas. Starship e mise devem
   estar instalados separadamente; o bootstrap avisa se faltarem.

O Neovim usa Catppuccin e tenta acompanhar as cores de `kdeglobals`; sem cores
válidas usa Mocha. O kitty recebe cores do KDE por um serviço de usuário e usa
paletas ANSI Catppuccin. GTK usa Breeze e as cores geradas pelo KDE. Aplicativos
Flatpak e libadwaita podem não respeitar todos os aspectos do tema do host.
Na sessão atual, Qt usa Kvantum Layan Dark e o KRunner acompanha o tema Plasma
Layan. O comando de greeter configura cores, fontes e cursor, não instala um
layout Layan completo; a aparência deve ser conferida no próximo login.

## Upgrade do Fedora

`./bootstrap/fedora-upgrade.sh --check` mostra a próxima versão, calculada a
partir de `rpm -E %fedora`. Sem `--check`, o script atualiza pacotes, baixa a
próxima versão e pergunta antes de reiniciar. Verifique antes se ela foi lançada
 e faça backup; não é necessário atualizar o Fedora 44 agora.

## Alternativa Catppuccin

`./theme/install.sh mocha sapphire` instala Catppuccin e altera o tema do
sistema, incluindo alguns componentes em `/usr/share` e overrides Flatpak.
Revise os scripts antes de executar; a reversão completa entre Catppuccin e
Layan ainda não foi validada.
