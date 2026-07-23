# distrobox-setup

Reconstrução dos scripts perdidos na troca de volta pro Fedora KDE, agora com
a base trocada de Arch para **Ubuntu 26.04** (`kode-d`), pra viabilizar
instalar o Claude Desktop dentro do container e exportar pro host.

## Responsabilidade de cada arquivo

| Arquivo | Faz | Não faz |
|---|---|---|
| `Dockerfile` | Builda a imagem `kode-d`: instala pacotes/dependências comuns (zsh, stow, neovim, Claude Desktop etc). | Não monta volumes, não conhece paths do host — bind mount é coisa de runtime, não de build. |
| `distrobox.ini.template` | Modelo genérico com placeholders (`{{NAME}}`, `{{IMAGE}}`, `{{USER}}`, `{{NVIDIA}}`), versionado no dotfiles. | Não é lido diretamente pelo distrobox — é só a receita. |
| `new-env.sh` | Recebe nome/imagem/nvidia por parâmetro, builda a imagem se faltar, substitui os placeholders do template e **anexa** a entrada no `distrobox.ini` real (evitando duplicar), cria o home isolado e assembla o ambiente. | Não instala pacotes (isso já veio da imagem). |
| `distrobox.ini` | Gerado/atualizado pelo `new-env.sh` a cada ambiente novo, em `~/Envs/distrobox.ini` — é o arquivo real que o `distrobox assemble` lê. **Não** fica no dotfiles: tem paths específicos desta máquina (ex: `home=/home/jefferson/Envs/nemu`), então não faz sentido versionar/sincronizar entre máquinas diferentes. | Não é editado à mão — sempre via `new-env.sh`, pra manter o padrão. |
| `bootstrap.sh` | Roda dentro do container já criado, com o volume montado: aplica Stow, configura shell, faz o `distrobox-export`. | Não builda imagem nem cria o container. |

## Arquitetura

Ambiente de desenvolvimento containerizado, em camadas, usando
**Podman + Distrobox**:

1. **Imagem base (`kode-d`)** — um único `Dockerfile`, hoje em
   Ubuntu 26.04 (era Arch), com o toolset comum a todos os ambientes: zsh,
   git, stow, neovim, build tools, e as libs que o Electron/Claude Desktop
   pedem. Buildada uma vez, reusada por todos os containers de projeto.

2. **Containers de projeto isolados** — cada projeto (ex: `cometa`,
   `claude-desktop`) roda em seu próprio container Distrobox, com **home
   isolado** em `~/Envs/{nome}` (não compartilha `$HOME` com o host nem
   entre projetos). Isso evita que configuração/estado de um projeto vaze
   pro outro.

3. **Dotfiles compartilhados** — um único repo de dotfiles em
   `~/dotfiles`, montado por volume (`rw` — você edita config de dentro
   do container também) em cada container e linkado no home isolado via
   **GNU Stow** (exceto o pacote `env/`, propositalmente fora do Stow —
   ver tabela acima). Config muda em um lugar só, todos os ambientes
   puxam dali. É onde mora o `distrobox.ini.template` (genérico,
   versionado) e o próprio `new-env.sh`/`bootstrap.sh`/`Dockerfile`.

4. **Bootstrap por container** (`bootstrap.sh`) — só configuração,
   nenhuma instalação de pacote (isso é tudo Dockerfile agora): zsh como
   shell padrão, Oh My Zsh (sempre **antes** do Stow, senão o `.zshrc`
   linkado é sobrescrito — e o Stow recebe um backup dos arquivos que
   ele criou, pra não dar conflito), depois Stow aplica os dotfiles
   (com `git submodule update` antes, cobrindo config do Neovim que já
   vem via submodule), identidade Git isolada por ambiente, e por fim
   exporta o Claude Desktop pro launcher do host.

5. **Template genérico + gerador** (`distrobox.ini.template` +
   `new-env.sh`) — em vez de escrever o `.ini` na mão pra cada ambiente
   novo, existe um template com placeholders (`{{NAME}}`, `{{IMAGE}}`,
   `{{USER}}`, `{{NVIDIA}}`). O `new-env.sh` recebe esses valores por
   parâmetro (com defaults sensatos), builda a imagem se faltar,
   substitui os placeholders e **anexa** a entrada resultante no
   `distrobox.ini` real — sem duplicar se o nome já existir. Cria o home
   isolado, assembla o ambiente e já dispara o bootstrap. Um comando por
   ambiente novo, ponta a ponta.

6. **`distrobox.ini` gerado, fora do dotfiles** — vive em
   `~/Envs/distrobox.ini`, não no repo. Motivo: tem paths específicos
   desta máquina (`home=/home/jefferson/Envs/nemu`), então não faz
   sentido versionar/sincronizar entre máquinas diferentes — cada
   máquina gera o seu, sempre com `new-env.sh`. Recriar tudo depois de
   perder o ambiente é rodar `distrobox assemble create --file
   ~/Envs/distrobox.ini`.


7. **Identidade dupla de GitHub** — resolvida via `~/.gitconfig` com
   `includeIf` condicional por diretório + chave SSH isolada por
   contexto (pessoal: `jeffersonxc22`; trabalho: `xenocometa`, chave
   `id_cometa`). Vive no repo de dotfiles, então o Stow já resolve.

8. **GPU em container** (quando aplicável) — Podman rootless + CDI
   (`nvidia-container-toolkit`, `no-cgroups=true`), sem workaround de
   SELinux, CDI gerado automaticamente por `nvidia-cdi-refresh`.

9. **Claude Desktop isolado por ambiente** — motivo da troca de base pra
   Ubuntu: a Anthropic distribui um build oficial (beta) só pra
   Debian/Ubuntu via apt. O app é instalado direto na **imagem base**
   (`kode-d`), não num container dedicado à parte — assim ele já
   nasce disponível em todo ambiente. Como cada ambiente tem home
   isolado, o `~/.config/Claude` (e portanto a sessão/autenticação) fica
   separado por projeto: `cometa` loga com uma conta, outro ambiente com
   outra, sem se misturar. O `bootstrap.sh` roda `distrobox-export --app
   claude-desktop` ao final de cada provisionamento, e o Distrobox
   sufixa o nome do container no `.desktop` exportado automaticamente —
   então o launcher do host mostra "Claude (cometa)", "Claude
   (outro-env)" etc. lado a lado, cada um abrindo a instância certa.

## Uso

```bash
chmod +x new-env.sh bootstrap.sh

# cria um ambiente de projeto (nvidia=true por padrão)
./new-env.sh cometa

# outro ambiente, sobrescrevendo imagem e/ou desabilitando nvidia
./new-env.sh sem-gpu-env kode-d:latest false
```

Cada chamada anexa uma entrada nova em `~/Envs/distrobox.ini` (gerada a
partir do `distrobox.ini.template`, que fica no dotfiles) e assembla o
ambiente na hora. O Claude Desktop já vem instalado na imagem, então
todo ambiente novo já nasce com sua própria instância isolada — não
precisa de um comando separado pra isso.

Se `~/Envs/distrobox.ini` já existir com várias entradas (recriando tudo
depois de perder o ambiente, por exemplo), dá pra assemblar de uma vez:

```bash
distrobox assemble create --file ~/Envs/distrobox.ini
```

## Instalando e exportando o Claude Desktop

O Dockerfile já inclui as libs que builds Electron/AppImage costumam pedir
(`libnss3`, `libgtk-3-0`, `libasound2t64`, `libgbm1`, `fuse`). Dentro do
container `claude-desktop`:

```bash
distrobox enter claude-desktop

# a Anthropic já tem um app oficial pra Linux (beta, Debian/Ubuntu only)
# via repositório apt próprio — exatamente o caso da nossa base Ubuntu
sudo curl -fsSLo /usr/share/keyrings/claude-desktop-archive-keyring.asc \
    https://downloads.claude.ai/claude-desktop/key.asc
echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/claude-desktop-archive-keyring.asc] https://downloads.claude.ai/claude-desktop/apt/stable stable main" \
    | sudo tee /etc/apt/sources.list.d/claude-desktop.list
sudo apt update && sudo apt install -y claude-desktop

# exporta o app pro menu/launcher do host
distrobox-export --app claude-desktop
```

Requisitos oficiais: Ubuntu 22.04+ ou Debian 12+, amd64/arm64 — nossa base
`kode-d` em Ubuntu 26.04 já atende. Vale lembrar que essa versão Linux
ainda é beta: Computer Use e ditado por voz não estão disponíveis (só via
CLI). Atualizações chegam pelo `apt upgrade` normal já que registramos o
repositório (em vez de baixar o `.deb` avulso, que não recebe update).

## Notas

- `bootstrap.sh` instala Oh My Zsh **antes** do `stow`, pra não sobrescrever
  o `.zshrc` linkado (decisão que já vínhamos seguindo).
- Ajuste `DOTFILES_REPO` em `bootstrap.sh` se a URL do repo mudou.
- Identidade dupla de GitHub (`~/.gitconfig` com `includeIf` + `id_cometa`)
  não é recriada automaticamente aqui — é só um lembrete no final do
  bootstrap. Se você tiver esse trecho versionado no dotfiles, o `stow`
  já resolve.
