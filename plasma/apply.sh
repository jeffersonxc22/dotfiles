#!/usr/bin/env bash
# Aplica apenas preferências selecionadas, sem copiar IDs de telas ou atividades.
set -euo pipefail
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ ${1:-} != --apply || $# != 1 ]]; then
    echo 'Uso: ./plasma/apply.sh --apply (sessão Plasma ativa; altera atalhos e painel)'
    exit 1
fi
for cmd in busctl python3 kwriteconfig6 systemctl; do
    command -v "$cmd" >/dev/null || { echo "Falta: $cmd" >&2; exit 1; }
done
for pkg in "$HOME/.local/share/kwin/scripts/krohnkite" "$HOME/.local/share/kwin/effects/kwin4_effect_geometry_change"; do
    [[ -f $pkg/metadata.json ]] || { echo "Instale primeiro: $pkg (veja plasma/README.md)" >&2; exit 1; }
done
for executable in kitty google-chrome systemd-run; do
    command -v "$executable" >/dev/null || { echo "Falta: $executable" >&2; exit 1; }
done
busctl --user get-property org.kde.KWin /VirtualDesktopManager org.kde.KWin.VirtualDesktopManager count >/dev/null
busctl --user introspect org.kde.plasmashell /PlasmaShell >/dev/null
backup="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/plasma-$(date +%Y%m%d%H%M%S)-$$"
mkdir -p "$backup"
for file in kwinrc kglobalshortcutsrc plasma-org.kde.plasma.desktop-appletsrc; do
    [[ ! -e $HOME/.config/$file ]] || cp -a "$HOME/.config/$file" "$backup/"
done
for name in workspace-move-follow app-launch-shortcuts; do
    target="$HOME/.local/share/kwin/scripts/$name"
    if [[ -e $target ]]; then mkdir -p "$backup/scripts"; cp -a "$target" "$backup/scripts/"; fi
    mkdir -p "$target"
    cp -a "$dir/kwin/scripts/$name/." "$target/"
done
mkdir -p "$HOME/.config/systemd/user" "$backup/systemd"
for name in shortcut-kitty.service shortcut-chrome.service; do
    [[ ! -e $HOME/.config/systemd/user/$name ]] || cp -a "$HOME/.config/systemd/user/$name" "$backup/systemd/"
    install -m 644 "$dir/systemd/user/$name" "$HOME/.config/systemd/user/$name"
done
echo "Backup: $backup"
systemctl --user daemon-reload
for key in screenGapLeft screenGapRight screenGapTop screenGapBetween; do
    kwriteconfig6 --file kwinrc --group Script-krohnkite --key "$key" 12
done
kwriteconfig6 --file kwinrc --group Script-krohnkite --key screenGapBottom 20
kwriteconfig6 --file kwinrc --group Script-krohnkite --key monocleMaximize --type bool false
kwriteconfig6 --file kwinrc --group Script-krohnkite --key binaryTreeLayoutOrder 1
kwriteconfig6 --file kwinrc --group Script-krohnkite --key tileLayoutOrder 11
for plugin in krohnkite kwin4_effect_geometry_change wobblywindows workspace-move-follow app-launch-shortcuts; do
    kwriteconfig6 --file kwinrc --group Plugins --key "${plugin}Enabled" --type bool true
done
kwriteconfig6 --file kwinrc --group Plugins --key maxpaddEnabled --type bool false
# Velocidade padrão do KDE (1.0); distros às vezes deixam 0.25, rápido demais.
kwriteconfig6 --file kdeglobals --group KDE --key AnimationDurationFactor "${PLASMA_ANIMATION_FACTOR:-1.0}"
kwriteconfig6 --file kwinrc --group Effect-kwin4_effect_geometry_change --key Duration "${PLASMA_GEOMETRY_DURATION:-500}"
busctl --user call org.kde.KWin /KWin org.kde.KWin reconfigure
if [[ $(busctl --user call org.kde.KWin /Scripting org.kde.kwin.Scripting isScriptLoaded s krohnkite) == 'b true' ]]; then
    busctl --user call org.kde.KWin /Scripting org.kde.kwin.Scripting unloadScript s krohnkite >/dev/null
fi
busctl --user call org.kde.KWin /Scripting org.kde.kwin.Scripting loadDeclarativeScript ss "$HOME/.local/share/kwin/scripts/krohnkite/contents/ui/main.qml" krohnkite >/dev/null
for name in workspace-move-follow app-launch-shortcuts; do
    if [[ $(busctl --user call org.kde.KWin /Scripting org.kde.kwin.Scripting isScriptLoaded s "$name") == 'b true' ]]; then
        busctl --user call org.kde.KWin /Scripting org.kde.kwin.Scripting unloadScript s "$name" >/dev/null
    fi
    busctl --user call org.kde.KWin /Scripting org.kde.kwin.Scripting loadScript ss "$HOME/.local/share/kwin/scripts/$name/contents/code/main.js" "$name" >/dev/null
done
busctl --user call org.kde.KWin /Scripting org.kde.kwin.Scripting start
for name in krohnkite workspace-move-follow app-launch-shortcuts; do
    [[ $(busctl --user call org.kde.KWin /Scripting org.kde.kwin.Scripting isScriptLoaded s "$name") == 'b true' ]] || { echo "Script não carregado: $name" >&2; exit 1; }
done
busctl --user call org.kde.KWin /Effects org.kde.kwin.Effects loadEffect s kwin4_effect_geometry_change >/dev/null
busctl --user call org.kde.KWin /Effects org.kde.kwin.Effects loadEffect s wobblywindows >/dev/null
get_desktops() { busctl --user --json=short get-property org.kde.KWin /VirtualDesktopManager org.kde.KWin.VirtualDesktopManager desktops; }
count=$(get_desktops | python3 -c 'import json,sys; print(len(json.load(sys.stdin)["data"]))')
while (( count < 10 )); do
    busctl --user call org.kde.KWin /VirtualDesktopManager org.kde.KWin.VirtualDesktopManager createDesktop us "$count" "$((count+1))"
    ((count+=1))
done
while IFS=$'\t' read -r index id; do
    busctl --user call org.kde.KWin /VirtualDesktopManager org.kde.KWin.VirtualDesktopManager setDesktopName ss "$id" "$((index+1))"
done < <(get_desktops | python3 -c 'import json,sys; [print(str(i)+"\t"+uid) for i,uid,name in json.load(sys.stdin)["data"][:10]]')
busctl --user set-property org.kde.KWin /VirtualDesktopManager org.kde.KWin.VirtualDesktopManager rows u 2

shortcut() { busctl --user call org.kde.kglobalaccel /kglobalaccel org.kde.KGlobalAccel setForeignShortcut asai "$@"; }
# Libera apenas os atalhos conhecidos que conflitam com o perfil.
for n in {1..9}; do
    shortcut 4 plasmashell "activate task manager entry $n" plasmashell "Ativar entrada $n do gerenciador de tarefas" 0
done
for n in {1..10}; do shortcut 4 kwin "Window to Desktop $n" kwin "Janela para a área de trabalho $n" 0; done
shortcut 4 plasmashell 'manage activities' plasmashell 'Mostrar seletor de atividade' 0
shortcut 4 plasmashell 'activate application launcher' plasmashell 'Ativar o lançador de aplicativos' 1 150994992
shortcut 4 kwin 'Edit Tiles' kwin 'Alternar Editor de Blocos' 0
shortcut 4 kwin KrohnkiteTileLayout kwin 'Krohnkite: Select Layout - Tile' 0
shortcut 4 kwin KrohnkiteToggleFloat kwin 'Krohnkite: Toggle Float' 0
shortcut 4 kwin KrohnkiteDecrease kwin 'Krohnkite: Decrease' 0
shortcut 4 kwin KrohnkiteMonocleLayout kwin 'Krohnkite: Select Layout - Monocle' 1 268435526
shortcut 4 kwin 'Show Desktop' kwin 'Espiar área de trabalho' 0
shortcut 4 kwin 'Minimize desktop windows' kwin 'Minimize desktop windows' 1 268435524
shortcut 4 kwin view_actual_size kwin 'Zoom para o tamanho atual' 0
shortcut 4 org_kde_powerdevil powerProfile 'Gerenciamento de energia' 'Trocar perfil de energia' 1 16777470
symbols=(33 64 35 36 37 16781911 38 42 40 41)
for n in {1..10}; do
    digit=$n; (( n == 10 )) && digit=0
    key=$((0x10000000+48+digit))
    if (( n <= 4 )); then
        shortcut 4 kwin "Switch to Desktop $n" kwin "Mudar para a área de trabalho $n" 3 "$key" $((0x05000030+n-1)) $((0x11000030+n-1))
    else
        shortcut 4 kwin "Switch to Desktop $n" kwin "Mudar para a área de trabalho $n" 1 "$key"
    fi
    shortcut 4 kwin "Move and follow desktop $n" kwin "Move window and follow to desktop $n" 2 $((0x10000000+symbols[n-1])) $((0x12000000+48+digit))
done
shortcut 4 kwin 'Window Close' kwin 'Fechar janela' 2 150994995 268435537
shortcut 4 org.kde.krunner.desktop _launch KRunner KRunner 5 150994993 134217760 16777362 268435488 16777250
shortcut 4 kwin 'Open Kitty window' kwin 'Open Kitty window' 1 268435540
shortcut 4 kwin 'Open Chrome window' kwin 'Open Chrome window' 1 268435522
shortcut 4 ksmserver 'Log Out' 'Gerenciamento de sessões' 'Mostrar tela para encerrar sessão' 2 218103815 268435544

# Seleciona o painel pela bandeja, não pelo ID específico desta máquina.
script='var ps=panels(); var found=false; for (var i=0;i<ps.length;i++) { var p=ps[i]; var trays=p.widgets("org.kde.plasma.systemtray"); if (!trays.length) continue; var pagers=p.widgets("org.kde.plasma.pager"); var pager=pagers.length ? pagers[0] : p.addWidget("org.kde.plasma.pager"); pager.currentConfigGroup=["General"]; pager.writeConfig("displayedText",0); pager.index=trays[0].index-(pager.index<trays[0].index ? 1 : 0); var launchers=p.widgets("org.kde.plasma.kickoff"); var launcher=launchers.length ? launchers[0] : p.addWidget("org.kde.plasma.kickoff"); launcher.currentConfigGroup=["General"]; launcher.writeConfig("icon","'"${PLASMA_LAUNCHER_ICON:-fedora-logo-icon}"'"); launcher.index=0; found=true; print("Painel configurado"); break; } if (!found) print("AVISO: painel com bandeja não encontrado");'
busctl --user call org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell evaluateScript s "$script"
echo 'Perfil aplicado. Teste os atalhos, o painel e as animações na sessão.'
