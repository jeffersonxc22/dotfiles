#!/usr/bin/env bash
# Diagnóstico temporário dos atalhos do Claude; grava em ~/dotfiles/diag-shortcuts.log
exec > "$HOME/dotfiles/diag-shortcuts.log" 2>&1
set -x
cd "$HOME/dotfiles"
bash plasma/claude-shortcuts.sh --apply; echo "exit=$?"
command -v claude-desktop; ls -l "$(command -v claude-desktop 2>/dev/null)" 2>&1
pgrep -a -f claude-desktop | head -5
G=(org.kde.kglobalaccel /kglobalaccel org.kde.KGlobalAccel)
busctl --user call "${G[@]}" allComponents
for a in "kwin Open\ Claude" "systemsettings.desktop _launch"; do :; done
busctl --user call "${G[@]}" shortcut as 4 kwin 'Open Claude' kwin 'Open Claude'
busctl --user call "${G[@]}" shortcut as 4 systemsettings.desktop _launch x x
id=$(awk -F= '/^\[com\.anthropic\.Claude\]/{s=1;next} /^\[/{s=0} s && $1 !~ /^_k_/ && $1 != "" {print $1; exit}' ~/.config/kglobalshortcutsrc)
busctl --user call "${G[@]}" shortcut as 4 com.anthropic.Claude "$id" x x
busctl --user call "${G[@]}" getComponent s com.anthropic.Claude
busctl --user call org.kde.KWin /Scripting org.kde.kwin.Scripting isScriptLoaded s app-launch-shortcuts
systemctl --user status shortcut-claude.service --no-pager
journalctl --user --since '-15 min' --no-pager | grep -iE 'claude|kglobalaccel|shortcut|portal' | tail -40
echo "XDG_SESSION_TYPE=$XDG_SESSION_TYPE"
