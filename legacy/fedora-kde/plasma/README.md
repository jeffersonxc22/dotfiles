# Perfil Plasma 6

Este diretório guarda o perfil de janelas, painel e atalhos da sessão KDE
Plasma. Não substitui arquivos completos do Plasma: IDs de telas, atividades e
desktops são específicos de cada instalação.

## Aplicação

O `bootstrap/install.sh` roda estes scripts na ordem certa (etapas 11 e 14
do [README](../README.md)). À mão, dentro da sessão Plasma:
`./plasma/prereqs.sh` instala Krohnkite **0.9.10.0**, o efeito
**Geometry Change 1.5** e o Layan, sem aplicar nada; `./plasma/theme.sh` aplica
toda a aparência.

- https://codeberg.org/anametologin/Krohnkite/releases/tag/0.9.10.0
- https://github.com/peterfajdiga/kwin4_effect_geometry_change/releases/tag/v1.5

Depois revise e execute `./plasma/apply.sh --apply`. Ele grava nas units o
caminho de `kitty` e `google-chrome-stable` encontrado no seu PATH, e usa o
`LOGO` de `/etc/os-release` como ícone do lançador (`PLASMA_LAUNCHER_ICON`
sobrescreve). O script cria um backup
em `~/.local/state/dotfiles/`, instala os scripts e serviços deste diretório,
configura os gaps e o efeito, cria até dez espaços sem apagar outros existentes,
e ajusta o primeiro painel com bandeja. Os dez primeiros espaços recebem nomes
numéricos; os outros são preservados. O script altera atalhos existentes,
inclusive Meta+0, Meta+Q, Meta+T e Meta+B. Revise conflitos específicos da
máquina antes de rodar: não há detecção completa de todos os conflitos.

Atalhos de movimento foram configurados para o teclado brasileiro ABNT2:
Meta+Shift+2 é registrado como Meta+@, por exemplo. Outros layouts podem
precisar de ajustes. Meta+1…9 e Meta+0 mudam de espaço; acrescentar Shift move
a janela ativa e acompanha a janela. Meta sozinho abre KRunner; Meta+Espaço
também. Meta+Q fecha a janela, Meta+T abre Kitty, Meta+B abre uma nova janela
do Chrome e Meta+X abre a tela de sessão. Meta+E e Meta+L dependem dos atalhos
existentes do KDE. O possível conflito de Meta+L com foco do Krohnkite deve ser
verificado em cada instalação. Alt+F4 e Ctrl+Alt+Del são preservados.

Krohnkite usa BTree como layout padrão, com gaps de 12 px e 20 px embaixo;
Meta+F alterna entre Monocle sem maximização automática e o layout anterior.
Meta+D minimiza as janelas da área de trabalho atual; restaure-as pelo painel.
Maxpadd fica desativado. Geometry Change anima o redimensionamento; confirme
visualmente a compatibilidade com a versão do KWin.

## Claude e Configurações

`./plasma/claude-shortcuts.sh --apply` define Meta+C para abrir/focar o app
Claude, Meta+I para o quick entry do Claude e move as Configurações do Sistema
de Meta+I (padrão do Plasma) para Meta+S; Krohnkite Increase fica sem atalho.
Também cria a regra KWin `claude-focus` (prevenção de roubo de foco: nenhuma),
porque no Wayland o atalho via portal não envia token de ativação e a janela
abria atrás das outras. O Claude precisa estar aberto e com o quick entry
ativado pelo menos uma vez, para o atalho existir no kglobalaccel.

## Layan

`appearance/` preserva o esquema Catppuccin Mocha Sapphire, a configuração Kvantum Dark e a
decoração Aurorae personalizada (transparência e botões coloridos), derivadas
do tema Layan de https://github.com/vinceliuice/Layan-kde e
https://github.com/vinceliuice/Layan-kvantum. `aurorae-Layan` foi modificado
em 2026-11-01; a licença GPL-3.0 do projeto
original está em `appearance/LICENSE-Layan-GPL-3.0`.
Instale os temas originais e o
Kvantum antes de aplicar essas personalizações. `plasma/prereqs.sh` instala
o Layan upstream e copia estes arquivos por cima, com backup em
`~/.local/state/dotfiles/`. 
`./plasma/theme.sh` aplica o perfil atual: estilo Layan com as cores
Catppuccin Mocha Sapphire. A tela de login é separada e requer sudo:
`sudo ./theme/greeter.sh` (Plasma Login Manager). O fundo sólido do login
ainda é escolhido à mão em Configurações > Tela de Login.
