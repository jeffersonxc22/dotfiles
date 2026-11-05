#!/usr/bin/env bash
# Confere a instalação dos dotfiles no PikaOS e grava o resultado em
# bootstrap/pikaos/verify.log (ignorado pelo git via **/*.log).
# Uso: ./bootstrap/pikaos/verify.sh   (dentro da sessão Plasma)
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
log="$repo/bootstrap/pikaos/verify.log"
export PATH="$HOME/.local/bin:$PATH"
ok=0 fail=0
check() { # check <descrição> <comando...>
    local d="$1"; shift
    if out="$("$@" 2>&1)"; then echo "OK   $d"; ((ok++)); else echo "FAIL $d :: ${out//$'\n'/ | }"; ((fail++)); fi
}
link_to() { [[ -L $1 && $(readlink -f "$1") == "$repo"/* ]]; }
{
echo "# verify $(date -Is) — $(. /etc/os-release; echo "$PRETTY_NAME")"
echo "## Binários"
for c in zsh kitty fzf zoxide bat eza fd rg nvim git stow starship mise gh wl-copy kpackagetool6 kwriteconfig6 google-chrome; do
    check "cmd $c" command -v "$c"
done
# No Debian o binário do keyd se chama keyd.rvaiya.
check "cmd keyd (keyd ou keyd.rvaiya)" bash -c 'command -v keyd.rvaiya || command -v keyd'
check "keyd ativo e casando o MX Mechanical" bash -c 'systemctl is-active -q keyd && [[ -e /etc/keyd/logitech.conf ]]'
check "fzf >= 0.48 (fzf --zsh)" fzf --zsh
check "nvim versão" nvim --version
check "shell padrão é zsh" bash -c '[[ $(getent passwd "$USER" | cut -d: -f7) == */zsh ]]'
echo "## Stow"
for f in .zshenv .gitconfig .config/zsh/.zshrc .config/nvim/init.lua .config/kitty/kitty.conf .config/starship.toml .config/mise/config.toml .config/herdr/config.toml; do
    check "link ~/$f" link_to "$HOME/$f"
done
echo "## zsh"
check "zsh carrega sem erro" zsh -ic 'exit'
check "plugins carregados" zsh -ic '(( $+functions[_zsh_autosuggest_start] )) && (( $+functions[_zsh_highlight] )) && (( $+functions[fzf-tab-complete] ))'
check "BAT_THEME existe" zsh -ic 'bat --list-themes | grep -qx "$BAT_THEME"'
echo "## mise"
check "mise ls" mise ls
check "herdr instalado" zsh -ic 'command -v herdr'
echo "## Fontes"
check "Cascadia Mono NF" bash -c 'fc-list | grep -qi "Cascadia Mono NF"'
check "Inter" bash -c 'fc-list | grep -qi "Inter"'
echo "## Plasma / tema"
check "Krohnkite" test -f "$HOME/.local/share/kwin/scripts/krohnkite/metadata.json"
check "Geometry Change" test -f "$HOME/.local/share/kwin/effects/kwin4_effect_geometry_change/metadata.json"
check "scripts KWin dos dotfiles" test -f "$HOME/.local/share/kwin/scripts/workspace-move-follow/metadata.json"
check "ColorScheme=CatppuccinMochaSapphire" bash -c '[[ $(kreadconfig6 --group General --key ColorScheme) == CatppuccinMochaSapphire ]]'
check "sem AccentColor personalizado" bash -c '[[ -z $(kreadconfig6 --group General --key AccentColor) ]]'
check "seleção = Sapphire" bash -c '[[ $(kreadconfig6 --group Colors:Selection --key BackgroundNormal | tr -d " ") == 116,199,236 ]]'
check "widgetStyle=kvantum" bash -c '[[ $(kreadconfig6 --group KDE --key widgetStyle) == kvantum ]]'
check "Kvantum LayanDark" bash -c 'grep -q LayanDark "$HOME/.config/Kvantum/kvantum.kvconfig"'
check "decoração Aurorae Layan" bash -c '[[ $(kreadconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme) == __aurorae__svg__Layan ]]'
check "cursor Catppuccin Mocha Sapphire" bash -c '[[ $(kreadconfig6 --file kcminputrc --group Mouse --key cursorTheme) == catppuccin-mocha-sapphire-cursors ]]'
check "ícones Slot-Dark-Tray (KDE)" bash -c '[[ $(kreadconfig6 --group Icons --key Theme) == Slot-Dark-Tray ]]'
check "ícones Slot-Dark-Tray (GTK)" grep -qx gtk-icon-theme-name=Slot-Dark-Tray "$HOME/.config/gtk-3.0/settings.ini"
check "bandeja Papirus-Dark" test -e "$HOME/.local/share/icons/Slot-Dark-Tray/22x22/panel/network-wireless-signal-excellent.svg"
check "painel opaco" bash -c 'grep -q "^panelOpacity=1" "$HOME/.config/plasmashellrc"'
check "Kvantum sem blur/transparência" bash -c 'f=$HOME/.config/Kvantum/Layan/LayanDark.kvconfig; grep -qx blurring=false "$f" && grep -qx translucent_windows=false "$f" && grep -qx highlight.color=#74c7ec "$f"'
check "KWin blur desligado" bash -c '[[ $(kreadconfig6 --file kwinrc --group Plugins --key blurEnabled) == false ]]'
check "pager antes da bandeja" python3 -c '
import re,os
t=open(os.path.expanduser("~/.config/plasma-org.kde.plasma.desktop-appletsrc")).read()
pl={(c,a):p for c,a,p in re.findall(r"^\[Containments\]\[(\d+)\]\[Applets\]\[(\d+)\]\n(?:[^\[\n].*\n)*?plugin=(\S+)",t,re.M)}
for c,o in re.findall(r"^\[Containments\]\[(\d+)\]\[General\]\nAppletOrder=(\S+)",t,re.M):
    k=[pl.get((c,a)) for a in o.split(";")]
    if "org.kde.plasma.pager" in k and "org.kde.plasma.systemtray" in k:
        assert k.index("org.kde.plasma.systemtray")-k.index("org.kde.plasma.pager")==1; break
else: raise SystemExit(1)'
check "Flatpak override global" bash -c 'flatpak override --user --show | grep -q ICON_THEME=Slot-Dark-Tray'
check "kitty oficial" bash -c '[[ $(readlink -f "$(command -v kitty)") == "$HOME/.local/kitty.app/"* ]]'
check "terminal padrão KDE = kitty" bash -c '[[ $(kreadconfig6 --group General --key TerminalService) == kitty.desktop ]]'
check "krohnkite habilitado" bash -c '[[ $(kreadconfig6 --file kwinrc --group Plugins --key krohnkiteEnabled) == true ]]'
check "krohnkite carregado" bash -c '[[ $(busctl --user call org.kde.KWin /Scripting org.kde.kwin.Scripting isScriptLoaded s krohnkite) == "b true" ]]'
check "10 áreas de trabalho" bash -c '(( $(busctl --user get-property org.kde.KWin /VirtualDesktopManager org.kde.KWin.VirtualDesktopManager count | cut -d" " -f2) >= 10 ))'
check "Kvantum SVG em Catppuccin" grep -q 74c7ec "$HOME/.config/Kvantum/Layan/LayanDark.svg"
check "SDDM com esquema Catppuccin" grep -q "ColorScheme=CatppuccinMochaSapphire" /var/lib/sddm/.config/kdeglobals
check "SDDM com cursor Catppuccin" grep -q "CursorTheme=catppuccin-mocha-sapphire-cursors" /etc/sddm.conf.d/kde_settings.conf
check "kitty-colors.path ativo" systemctl --user is-active kitty-colors.path
check "kitty-theme.conf" test -s "$HOME/.cache/dotfiles/kitty-theme.conf"
echo "## Resumo: $ok OK, $fail FAIL"
} | tee "$log"
