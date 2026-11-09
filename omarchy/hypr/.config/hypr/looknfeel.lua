-- Change the default Omarchy look'n'feel.

-- Opt another application in to Omarchy's standard transparency.
-- Find its class with: hyprctl clients
-- o.transparent_window("my-app")
-- o.transparent_window("my-app", "0.9 0.85") -- Custom active/inactive opacity.

-- Todos os apps translúcidos para o blur aparecer (GTK, Flatpak, Chromium, Electron):
-- eles desenham fundo opaco, então só a opacidade da janela inteira mostra o desfoque.
o.transparent_window(".*", "0.92 0.88")
-- Terminais voltam ao padrão do Omarchy: o kitty já tem fundo próprio a 65% com
-- texto nítido, e a regra acima apagaria o texto junto. Mesma lista do
-- default/hypr/apps/terminals.lua (por classe: a regra por tag não vence a de cima).
o.transparent_window("(Alacritty|kitty|com.mitchellh.ghostty|foot|org\\.codeberg\\.dnkl\\.foot|wezterm|org\\.omarchy\\..*|TUI\\..*)")
-- Exceções opacas: vídeo e imagem; o Dolphin já é translúcido pelo Kvantum (texto nítido).
o.window("(mpv|imv|org\\.kde\\.dolphin)", { opaque = true })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#general
-- hl.config({
--   general = {
--     -- No gaps between windows or borders.
--     gaps_in = 0,
--     gaps_out = 0,
--     border_size = 0,
--
--     -- Change to niri-like side-scrolling layout.
--     layout = "scrolling",
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#decoration
-- hl.config({
--   decoration = {
--     -- Use round window corners.
--     rounding = 8,
--
--     -- Dim unfocused windows (0.0 = no dim, 1.0 = fully dimmed).
--     dim_inactive = true,
--     dim_strength = 0.15,
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#animations
-- hl.config({
--   animations = {
--     -- Disable all animations.
--     enabled = false,
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#layout
-- hl.config({
--   layout = {
--     -- Avoid overly wide single-window layouts on wide screens.
--     single_window_aspect_ratio = { 1, 1 },
--   },
-- })

-- https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/
-- hl.config({
--   scrolling = {
--     -- See only one column per screen instead of two.
--     column_width = 0.97,
--   },
-- })

-- ---------------------------------------------------------------------------
-- Cursor Future-cursors (instalado por ~/Projetos/dotfiles/cursor.sh)
-- ---------------------------------------------------------------------------
-- Tema em ~/.local/share/icons/Future-cursors; GTK e X11 seguem pelo gsettings
-- e por ~/.local/share/icons/default (pacote stow "cursor").
hl.env("XCURSOR_THEME", "Future-cursors")
hl.env("XCURSOR_SIZE", "24")
