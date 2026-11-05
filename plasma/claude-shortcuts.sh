#!/usr/bin/env bash
# Atalhos do Claude e das Configurações do Sistema + regra KWin de foco.
#   Meta+C  abre/foca o app Claude
#   Meta+I  quick entry (prompt) do Claude, vindo para frente
#   Meta+S  Configurações do Sistema (padrão do Plasma era Meta+I)
set -euo pipefail
if [[ ${1:-} != --apply || $# != 1 ]]; then
    echo 'Uso: ./plasma/claude-shortcuts.sh --apply (sessão Plasma ativa)'
    exit 1
fi
for cmd in busctl kwriteconfig6 kreadconfig6 systemctl claude-desktop; do
    command -v "$cmd" >/dev/null || { echo "Falta: $cmd" >&2; exit 1; }
done
cfg="$HOME/.config"
backup="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/claude-shortcuts-$(date +%Y%m%d%H%M%S)-$$"
mkdir -p "$backup"
for f in kglobalshortcutsrc kwinrulesrc; do [[ ! -e $cfg/$f ]] || cp -a "$cfg/$f" "$backup/"; done
echo "Backup: $backup"

shortcut() { busctl --user call org.kde.kglobalaccel /kglobalaccel org.kde.KGlobalAccel setForeignShortcut asai "$@" >/dev/null; }
META=$((0x10000000))
META_C=$((META + 0x43)); META_I=$((META + 0x49)); META_S=$((META + 0x53))

# 1) Libera Meta+I: Configurações -> Meta+S e Krohnkite Increase sem atalho.
shortcut 4 systemsettings.desktop _launch 'Configurações do sistema' 'Configurações do sistema' 1 "$META_S"
shortcut 4 kwin KrohnkiteIncrease kwin 'Krohnkite: Increase' 0

# 2) Meta+C abre/foca o app. Atalho em .desktop sem X-KDE-Shortcuts é ignorado
#    pelo kglobalaccel, então usa o script KWin app-launch-shortcuts + systemd.
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
install -Dm644 "$dir/systemd/user/shortcut-claude.service" "$HOME/.config/systemd/user/shortcut-claude.service"
systemctl --user daemon-reload
target="$HOME/.local/share/kwin/scripts/app-launch-shortcuts"
mkdir -p "$target"; cp -a "$dir/kwin/scripts/app-launch-shortcuts/." "$target/"
kwriteconfig6 --file kwinrc --group Plugins --key app-launch-shortcutsEnabled --type bool true
S=(org.kde.KWin /Scripting org.kde.kwin.Scripting)
if [[ $(busctl --user call "${S[@]}" isScriptLoaded s app-launch-shortcuts) == 'b true' ]]; then
    busctl --user call "${S[@]}" unloadScript s app-launch-shortcuts >/dev/null
fi
busctl --user call "${S[@]}" loadScript ss "$target/contents/code/main.js" app-launch-shortcuts >/dev/null
busctl --user call "${S[@]}" start
shortcut 4 kwin 'Open Claude' kwin 'Open Claude' 1 "$META_C"

# 3) Meta+I no atalho de quick entry que o Claude registrou pelo portal.
qe_id=$(awk -F= '/^\[com\.anthropic\.Claude\]/{s=1;next} /^\[/{s=0} s && $1 !~ /^_k_/ && $1 != "" {print $1; exit}' "$cfg/kglobalshortcutsrc")
if [[ -n $qe_id ]]; then
    qe_name=$(awk -F= -v id="$qe_id" '$1==id{n=split($0,a,","); print a[n]; exit}' "$cfg/kglobalshortcutsrc")
    shortcut 4 com.anthropic.Claude "$qe_id" Claude "${qe_name:-Claude quick entry}" 1 "$META_I"
    echo "Quick entry ($qe_id) -> Meta+I"
else
    echo 'AVISO: atalho de quick entry do Claude não encontrado. Abra o Claude e ative o' >&2
    echo '       atalho de quick entry nas configurações dele; depois rode este script de novo.' >&2
fi

# 4) Regra KWin: janelas do Claude ignoram a prevenção de roubo de foco
#    (no Wayland o atalho via portal não traz token de ativação -> abria atrás).
rule=claude-focus
rules=$(kreadconfig6 --file kwinrulesrc --group General --key rules)
if [[ ,$rules, != *,$rule,* ]]; then
    rules=${rules:+$rules,}$rule
fi
count=$(awk -F, '{print NF}' <<<"$rules")
w() { kwriteconfig6 --file kwinrulesrc --group "$rule" --key "$@"; }
w Description 'Claude: trazer para frente'
w wmclass anthropic
w wmclassmatch 2          # substring (app_id Wayland ou WM_CLASS do XWayland)
w wmclasscomplete --type bool false
w fsplevel 0              # prevenção de roubo de foco: nenhuma
w fsplevelrule 2          # forçar
kwriteconfig6 --file kwinrulesrc --group General --key rules "$rules"
kwriteconfig6 --file kwinrulesrc --group General --key count "$count"
busctl --user call org.kde.KWin /KWin org.kde.KWin reconfigure

echo 'Pronto: Meta+C (Claude), Meta+I (quick entry), Meta+S (Configurações).'
echo 'Se o Meta+I não responder, feche o Claude por completo (bandeja > Sair) e abra de novo.'
