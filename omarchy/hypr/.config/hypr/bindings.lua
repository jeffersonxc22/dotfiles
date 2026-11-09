-- Keep only your personal keybinding overrides here. Add new bindings with
-- o.bind or replace defaults with o.rebind.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding. o.rebind takes the same arguments as o.bind.
-- This example replaces the default file manager with Flea.
-- o.rebind("SUPER + SHIFT + F", "File manager", { launch = "flea" })

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, { panel = "omarchy.emojis" })

-- ---------------------------------------------------------------------------
-- Atalhos trazidos do perfil KDE (legacy/fedora-kde/plasma)
-- ---------------------------------------------------------------------------

-- Super+T abre o terminal padrão (era: alternar flutuante/mosaico).
-- Hoje é o foot; vira kitty quando rodar `omarchy install terminal kitty`.
o.rebind("SUPER + T", "Terminal", o.launch_terminal())
-- Flutuante/mosaico passa para Super+Alt+T (Super+Shift+T é "Atividade").
o.bind("SUPER + ALT + T", "Toggle window floating/tiling", hl.dsp.window.float({ action = "toggle" }))

-- Super+B abre o navegador padrão do Omarchy (Chromium), igual Super+Shift+B.
o.bind("SUPER + B", "Browser", { omarchy = "browser" })

-- Super+X abre o menu de sistema/energia (era: recortar universal).
o.rebind("SUPER + X", "System menu", { menu = "system" })

-- Super+I abre o Claude Code (era: alternar idioma de entrada).
o.rebind("SUPER + I", "Claude Code", "cd ~/Projetos && omarchy-agent")

-- O omarchy-agent só sai do $HOME para ~/Work; aqui a pasta de trabalho é ~/Projetos.
o.rebind("SUPER + SHIFT + CTRL + A", "Agent", "cd ~/Projetos && omarchy-agent --pick")

-- Super+S tira print (era: alternar scratchpad -> foi para Super+Shift+Alt+S).
o.rebind("SUPER + S", "Screenshot", "omarchy-capture-screenshot")
o.bind("SUPER + SHIFT + ALT + S", "Toggle scratchpad", hl.dsp.workspace.toggle_special("scratchpad"))

-- Gerenciador de arquivos: Dolphin no lugar do Nautilus (Super+E é tecla livre).
o.bind("SUPER + E", "File manager", { launch = "dolphin" })
o.rebind("SUPER + SHIFT + F", "File manager", { launch = "dolphin" })
o.rebind("SUPER + ALT + SHIFT + F", "File manager (cwd)", 'uwsm-app -- dolphin --new-window "$(omarchy-cmd-terminal-cwd)"')

-- Super+F maximiza (mantém barra e gaps); tela cheia de verdade vai para Super+Alt+F.
o.rebind("SUPER + F", "Maximize", hl.dsp.window.fullscreen({ mode = "maximized" }))
o.rebind("SUPER + ALT + F", "Full screen", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
