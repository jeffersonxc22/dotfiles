#!/usr/bin/env bash
# Perfil visual: estilo Layan (Kvantum, decoração Aurorae, tema Plasma) com as
# cores oficiais Catppuccin Mocha + Sapphire, sem blur e sem transparência,
# ícones Slot-Dark-Icons (bandeja Papirus), cursor Catppuccin, fontes Inter e
# Cascadia, fundo sólido Mocha Base na área de trabalho e no bloqueio,
# propagado para KDE, GTK, kitty e Flatpak. Também põe o pager à direita,
# logo antes da bandeja. É a única fonte da aparência.
#
# Uso: ./plasma/theme.sh   (dentro da sessão Plasma)
# Pré-requisito: ./plasma/prereqs.sh (Layan instalado).
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
app="$repo/plasma/appearance"
scheme=CatppuccinMochaSapphire
for cmd in kwriteconfig6 plasma-apply-colorscheme busctl python3 systemctl; do
    command -v "$cmd" >/dev/null || { echo "Falta: $cmd" >&2; exit 1; }
done
[[ -d $HOME/.config/Kvantum/Layan ]] || { echo "Layan não instalado: rode plasma/prereqs.sh" >&2; exit 1; }

backup="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/theme-$(date +%Y%m%d%H%M%S)"
mkdir -p "$backup"
save() { [[ -e $1 ]] && { mkdir -p "$backup/$(dirname "${1#$HOME/}")"; cp -a "$1" "$backup/${1#$HOME/}"; }; return 0; }

echo "== Esquema de cores $scheme"
save "$HOME/.local/share/color-schemes/$scheme.colors"
install -Dm644 "$app/$scheme.colors" "$HOME/.local/share/color-schemes/$scheme.colors"
# Um AccentColor personalizado (o Layan deixa amarelo 232,203,45) sobrescreve
# seleção e foco do esquema; remove para valer o Sapphire oficial.
kwriteconfig6 --file kdeglobals --group General --key AccentColor --delete
kwriteconfig6 --file kdeglobals --group General --key LastUsedCustomAccentColor --delete
kwriteconfig6 --file kdeglobals --group General --key accentColorFromWallpaper --type bool false
# Reaplica mesmo se o esquema já estiver selecionado (o comando ignora o repetido).
plasma-apply-colorscheme BreezeDark >/dev/null
plasma-apply-colorscheme "$scheme"

echo "== Kvantum LayanDark com paleta Catppuccin, opaco e sem blur"
save "$HOME/.config/Kvantum/Layan/LayanDark.kvconfig"
install -m644 "$app/LayanDark.kvconfig" "$HOME/.config/Kvantum/Layan/LayanDark.kvconfig"
# O SVG do Kvantum desenha fundos, seleção e botões com cores próprias; a
# versão dos dotfiles troca a paleta Layan pela Catppuccin Mocha.
save "$HOME/.config/Kvantum/Layan/LayanDark.svg"
install -m644 "$app/LayanDark.svg" "$HOME/.config/Kvantum/Layan/LayanDark.svg"
if command -v kvantummanager >/dev/null; then kvantummanager --set LayanDark; fi
kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle kvantum

echo "== Decoração Aurorae Layan e fontes"
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library org.kde.kwin.aurorae
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme __aurorae__svg__Layan
ui_font="Inter,10,-1,5,50,0,0,0,0,0"
for key in font menuFont toolBarFont taskbarFont; do
    kwriteconfig6 --file kdeglobals --group General --key "$key" "$ui_font"
done
kwriteconfig6 --file kwinrc --group WM --key activeFont "$ui_font"
kwriteconfig6 --file kdeglobals --group General --key smallestReadableFont "Inter,8,-1,5,50,0,0,0,0,0"
kwriteconfig6 --file kdeglobals --group General --key fixed "Cascadia Mono NF,10,-1,5,50,0,0,0,0,0"

echo "== Tema Plasma Layan seguindo o esquema Catppuccin"
pt="$HOME/.local/share/plasma/desktoptheme/Layan"
if [[ -d $pt ]]; then
    save "$pt/colors"
    install -m644 "$app/$scheme.colors" "$pt/colors"
fi
command -v plasma-apply-desktoptheme >/dev/null && plasma-apply-desktoptheme Layan

echo "== Desligando blur/contraste do KWin"
kwriteconfig6 --file kwinrc --group Plugins --key blurEnabled --type bool false
kwriteconfig6 --file kwinrc --group Plugins --key contrastEnabled --type bool false
for effect in blur contrast; do
    busctl --user call org.kde.KWin /Effects org.kde.kwin.Effects unloadEffect s "$effect" >/dev/null 2>&1 || true
done
busctl --user call org.kde.KWin /KWin org.kde.KWin reconfigure >/dev/null 2>&1 || true

echo "== Ícones Slot-Dark-Icons (L4ki/Slot-Plasma-Themes)"
icons_commit=ac0382d7bf096d4e061934691cd5f4543b02aac4
slot_src="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/src/Slot-Plasma-Themes"
if [[ ! -d $slot_src/.git ]]; then
    git clone --quiet --filter=blob:none --no-checkout https://github.com/L4ki/Slot-Plasma-Themes "$slot_src"
fi
git -C "$slot_src" sparse-checkout set "Slot Icons Themes/Slot-Dark-Icons"
git -C "$slot_src" fetch --quiet origin "$icons_commit" 2>/dev/null || true
git -C "$slot_src" checkout --quiet "$icons_commit"
icons_dst="$HOME/.local/share/icons/Slot-Dark-Icons"
if [[ -e $icons_dst ]]; then save "$icons_dst"; rm -rf "$icons_dst"; fi
mkdir -p "$(dirname "$icons_dst")"
cp -a "$slot_src/Slot Icons Themes/Slot-Dark-Icons" "$icons_dst"
gtk-update-icon-cache -f -t "$icons_dst" >/dev/null 2>&1 || true
# Bandeja com os ícones de painel do Papirus-Dark (arredondados); o resto
# herda do Slot-Dark-Icons. Os diretórios são links para o Papirus do dnf.
icon_theme=Slot-Dark-Tray
tray="$HOME/.local/share/icons/$icon_theme"
papirus=/usr/share/icons/Papirus-Dark
if [[ -d $papirus/22x22/panel ]]; then
    mkdir -p "$tray"
    dirs=()
    for size in 16 22 24; do
        [[ -d $papirus/${size}x${size}/panel ]] || continue
        mkdir -p "$tray/${size}x${size}"
        ln -sfn "$papirus/${size}x${size}/panel" "$tray/${size}x${size}/panel"
        dirs+=("${size}x${size}/panel")
    done
    {
        printf '[Icon Theme]\nName=%s\nComment=Slot-Dark-Icons com bandeja Papirus-Dark\n' "$icon_theme"
        printf 'Inherits=Slot-Dark-Icons,Papirus-Dark,breeze-dark,breeze,hicolor\n'
        printf 'Directories=%s\n' "$(IFS=,; echo "${dirs[*]}")"
        for d in "${dirs[@]}"; do
            printf '\n[%s]\nContext=Status\nSize=%s\nType=Fixed\n' "$d" "${d%%x*}"
        done
    } > "$tray/index.theme"
else
    echo "aviso: Papirus-Dark não instalado; bandeja fica com Slot/Breeze." >&2
    icon_theme=Slot-Dark-Icons
fi
changeicons="$(command -v plasma-changeicons || ls /usr/libexec/plasma-changeicons 2>/dev/null || true)"
if [[ -n $changeicons ]]; then "$changeicons" "$icon_theme"; else kwriteconfig6 --file kdeglobals --group Icons --key Theme "$icon_theme"; fi

echo "== Cursor Catppuccin Mocha Sapphire (catppuccin/cursors v2.0.0)"
cursor=catppuccin-mocha-sapphire-cursors
cursor_sha=33f47ba605bde24b5f5369bfa9575e06d507cc09db77bdefb06f873519cd011a
if [[ ! -f $HOME/.local/share/icons/$cursor/index.theme ]]; then
    tmpc="$(mktemp -d)"
    curl -fsSL -o "$tmpc/c.zip" "https://github.com/catppuccin/cursors/releases/download/v2.0.0/$cursor.zip"
    echo "$cursor_sha  $tmpc/c.zip" | sha256sum -c --quiet
    unzip -q "$tmpc/c.zip" -d "$HOME/.local/share/icons/"
    rm -rf "$tmpc"
fi
plasma-apply-cursortheme "$cursor" --size 24 || kwriteconfig6 --file kcminputrc --group Mouse --key cursorTheme "$cursor"

echo "== GTK, kitty e Flatpak"
busctl --user call org.kde.kded6 /kded org.kde.kded6 reconfigure >/dev/null 2>&1 || true
"$repo/theme/gtk.sh" mocha
if command -v gsettings >/dev/null; then
    gsettings set org.gnome.desktop.interface cursor-theme "$cursor" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface icon-theme "$icon_theme" 2>/dev/null || true
fi
"$repo/theme/kitty-colors.sh"
if command -v flatpak >/dev/null; then
    "$repo/theme/flatpak.sh"
    # Breeze GTK dentro do sandbox lê o colors.css gerado pelo KDE.
    if flatpak remotes --columns=name | grep -qx flathub; then
        flatpak install -y --noninteractive flathub org.gtk.Gtk3theme.Breeze || echo "aviso: não instalou org.gtk.Gtk3theme.Breeze" >&2
    fi
fi

echo "== Fundo sólido Mocha Base (#1e1e2e): área de trabalho e tela de bloqueio"
base='#1e1e2e'
busctl --user call org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell evaluateScript s \
    "desktops().forEach(function (d) { d.wallpaperPlugin = 'org.kde.color'; d.currentConfigGroup = ['Wallpaper', 'org.kde.color', 'General']; d.writeConfig('Color', '$base'); });" >/dev/null
save "$HOME/.config/kscreenlockerrc"
kwriteconfig6 --file kscreenlockerrc --group Greeter --key WallpaperPlugin org.kde.color
kwriteconfig6 --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.color --group General --key Color "$base"

echo "== Pager à direita (antes da bandeja)"
rc="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
save "$rc"
systemctl --user stop plasma-plasmashell.service
python3 - "$rc" <<'PY'
import re, sys
path = sys.argv[1]
text = open(path, encoding="utf-8").read()
pattern = r'^\[Containments\]\[(\d+)\]\[Applets\]\[(\d+)\]\n(?:[^\[\n].*\n)*?plugin=(\S+)'
plugins = {(c, a): p for c, a, p in re.findall(pattern, text, re.M)}
changed = False
def fix(m):
    global changed
    cont, order = m.group(1), m.group(2).split(";")
    kinds = {a: plugins.get((cont, a)) for a in order}
    pager = next((a for a in order if kinds[a] == "org.kde.plasma.pager"), None)
    tray = next((a for a in order if kinds[a] == "org.kde.plasma.systemtray"), None)
    if not pager or not tray:
        return m.group(0)
    order.remove(pager)
    order.insert(order.index(tray), pager)
    changed = True
    return f"[Containments][{cont}][General]\nAppletOrder={';'.join(order)}"
text = re.sub(r'^\[Containments\]\[(\d+)\]\[General\]\nAppletOrder=(\S+)', fix, text, flags=re.M)
open(path, "w", encoding="utf-8").write(text)
print("  AppletOrder ajustado" if changed else "  AVISO: painel com pager e bandeja não encontrado")
PY
echo "== Painel opaco (cor do tema, sem translucidez adaptativa)"
python3 - "$rc" <<'PY' | while read -r panel; do
import re, sys
text = open(sys.argv[1], encoding="utf-8").read()
for c in re.findall(r'^\[Containments\]\[(\d+)\]\n(?:[^\[\n].*\n)*?plugin=org\.kde\.panel$', text, re.M):
    print(c)
PY
    kwriteconfig6 --file plasmashellrc --group PlasmaViews --group "Panel $panel" --key panelOpacity 1
    echo "  painel $panel opaco"
done
systemctl --user start plasma-plasmashell.service

echo
echo "Tema aplicado. Backup: $backup"
echo "Tela de login: rode  sudo $repo/theme/greeter.sh"
echo "Apps já abertos (Qt/GTK/Flatpak) pegam o tema ao reabrir."
