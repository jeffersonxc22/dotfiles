#!/usr/bin/env bash
# Confere a instalação dos dotfiles e grava o resultado em
# bootstrap/verify.log (ignorado pelo git via **/*.log).
# Uso: ./bootstrap/verify.sh   (dentro da sessão Plasma)
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
log="$repo/bootstrap/verify.log"
dm="$(basename "$(readlink -f /etc/systemd/system/display-manager.service)" .service)"
dm_home="$(getent passwd "$dm" | cut -d: -f6)"
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
for c in zsh kitty fzf zoxide bat eza fd rg nvim git stow starship mise gh podman wl-copy kpackagetool6 kwriteconfig6 kvantummanager; do
    check "cmd $c" command -v "$c"
done
check "cmd google-chrome" bash -c 'command -v google-chrome-stable || command -v google-chrome'
check "cmd keyd" command -v keyd
check "keyd ativo e casando o MX Mechanical" bash -c 'systemctl is-active -q keyd && [[ -e /etc/keyd/logitech.conf ]]'
check "fzf >= 0.48 (fzf --zsh)" fzf --zsh
check "nvim versão" nvim --version
check "shell padrão é zsh" bash -c '[[ $(getent passwd "$USER" | cut -d: -f7) == */zsh ]]'
echo "## Stow"
for f in .zshenv .gitconfig .config/zsh/.zshrc .config/nvim/init.lua .config/kitty/kitty.conf .config/starship.toml .config/mise/config.toml; do
    check "link ~/$f" link_to "$HOME/$f"
done
echo "## zsh"
check "zsh carrega sem erro" zsh -ic 'exit'
check "plugins carregados" zsh -ic '(( $+functions[_zsh_autosuggest_start] )) && (( $+functions[_zsh_highlight] )) && (( $+functions[fzf-tab-complete] ))'
check "função podman-gpu" zsh -ic '(( $+functions[podman-gpu] ))'
check "BAT_THEME existe" zsh -ic 'bat --list-themes | grep -qx "$BAT_THEME"'
echo "## mise"
check "mise ls" mise ls
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
check "greeter ($dm) com esquema Catppuccin" bash -c 'f="$1/.config/kdeglobals"; grep -q "ColorScheme=CatppuccinMochaSapphire" "$f" 2>/dev/null || sudo -n grep -q "ColorScheme=CatppuccinMochaSapphire" "$f"' _ "$dm_home"
check "greeter ($dm) com cursor Catppuccin" bash -c 'f="$1/.config/kcminputrc"; grep -q "cursorTheme=catppuccin-mocha-sapphire-cursors" "$f" 2>/dev/null || sudo -n grep -q "cursorTheme=catppuccin-mocha-sapphire-cursors" "$f"' _ "$dm_home"
check "kitty-colors.path ativo" systemctl --user is-active kitty-colors.path
check "kitty-theme.conf" test -s "$HOME/.cache/dotfiles/kitty-theme.conf"
check "fundo sólido na área de trabalho" grep -q "wallpaperplugin=org.kde.color" "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
check "fundo sólido no bloqueio" bash -c '[[ $(kreadconfig6 --file kscreenlockerrc --group Greeter --key WallpaperPlugin) == org.kde.color ]]'
echo "## Programas"
for c in google-chrome-stable slack claude; do check "cmd $c" command -v "$c"; done
check "Chrome navegador padrão" bash -c '[[ $(xdg-settings get default-web-browser) == google-chrome.desktop ]]'
if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi -L >/dev/null 2>&1; then
echo "## NVIDIA + Podman (CDI)"
check "cmd nvidia-ctk" command -v nvidia-ctk
check "pacote nvidia-container-toolkit" rpm -q nvidia-container-toolkit
check "dispositivo CDI nvidia.com/gpu=all" bash -c 'nvidia-ctk cdi list | grep -q "nvidia.com/gpu=all"'
check "spec CDI /var/run/cdi/nvidia.yaml" test -s /var/run/cdi/nvidia.yaml
check "nvidia-cdi-refresh.path ativo" systemctl is-active nvidia-cdi-refresh.path
fi
echo "## Home PARA"
for d in Projetos Áreas Recursos Arquivados; do check "~/$d" test -d "$HOME/$d"; done
check "~/Desktop em Projetos" test -d "$HOME/Projetos/Desktop"
check "~/Público em Projetos" test -d "$HOME/Projetos/Público"
check "~/Documentos em Áreas" test -d "$HOME/Áreas/Documentos"
for d in Downloads Imagens Músicas Vídeos Modelos; do
    check "~/$d em Recursos" test -d "$HOME/Recursos/$d"
done
check "XDG_DESKTOP_DIR em Projetos" test "$(xdg-user-dir DESKTOP)" = "$HOME/Projetos/Desktop"
check "XDG_DOCUMENTS_DIR em Áreas" test "$(xdg-user-dir DOCUMENTS)" = "$HOME/Áreas/Documentos"
check "XDG_PROJECTS_DIR em Projetos" test "$(xdg-user-dir PROJECTS)" = "$HOME/Projetos"
check "XDG_PUBLICSHARE_DIR em Projetos" test "$(xdg-user-dir PUBLICSHARE)" = "$HOME/Projetos/Público"
for k in DOWNLOAD MUSIC PICTURES VIDEOS TEMPLATES; do
    check "XDG_${k}_DIR em Recursos" bash -c '[[ $(xdg-user-dir "$1") == "$HOME/Recursos/"* ]]' _ "$k"
done
for d in Desktop Documents Downloads Music Pictures Public Templates Videos \
    "Área de trabalho" Documentos Música Músicas Imagens Público Modelos Vídeos; do
    check "sem ~/$d" test ! -e "$HOME/$d"
done
echo "## Resumo: $ok OK, $fail FAIL"
} | tee "$log"
