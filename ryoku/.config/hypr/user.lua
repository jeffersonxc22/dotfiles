-- --- hypr/user.lua --------------------------------------------------------
-- Your Hyprland overrides, in Ryoku's `hl` Lua API. Loaded LAST, so anything
-- here wins over Ryoku's defaults and over Ryoku Settings. Updates never touch
-- it. Reach for it only for raw config the GUI does not expose.
--
-- --- who owns what --------------------------------------------------------
--   Ryoku defaults   the base modules           replaced by updates   don't edit
--   Ryoku Settings   settings*.lua, rebinds.lua the GUI writes these edit in-app
--   you              this file (edit it here); whole-file forks in user_edits  yours
--
-- --- take over a whole module ---------------------------------------------
-- Copy it into the overlay at the same path and edit there, e.g.
--   ~/.config/ryoku/user_edits/hypr/modules/binds.lua
-- You then own that file: `ryoku doctor` warns when an update changes the
-- original, and `ryoku reset hypr/modules/binds.lua` hands it back.
--
-- --- examples -------------------------------------------------------------
-- hl.bind("SUPER + SHIFT + T", hl.dsp.exec_cmd("kitty"))
-- hl.window_rule({ name = "float-mpv", match = { class = "mpv" }, float = true })
-- hl.config({ general = { border_size = 3 } })

-- --- keyboards: one layout per device -------------------------------------
-- Notebook keeps pt-BR. The Logitech MX Mechanical Mini gets en-US intl
-- through its own device rule. Device rules match the name exactly, so a
-- wrong name fails silently: confirm with
--   hyprctl devices -j | jq -r '.keyboards[]|.name'
hl.device({ name = "at-translated-set-2-keyboard", kb_layout = "br" })
hl.device({ name = "mx-mchncl-m-keyboard", kb_layout = "us", kb_variant = "intl" })

-- --- workspaces: round-robin across three outputs -------------------------
-- ws 1 -> eDP-2, ws 2 -> DP-1, ws 3 -> DP-3, ws 4 -> eDP-2, ...
-- The order below is physical, left to right. Confirm the real names with
-- `hyprctl monitors all`; a name that does not exist is simply skipped.
-- DESKTOPS * 10 covers three Ryoku desktop blocks (ws 1..30).
--
-- Only outputs that are actually connected take part: a workspace bound to a
-- missing output cannot be focused (Super+2 would do nothing on the laptop
-- alone), so with a single screen no rule is written and Hyprland keeps its
-- default behaviour. Plugging a screen reloads the config after autoscale so
-- the cycle picks it up. Confirm the real names with `hyprctl monitors all`.
hl.on("monitor.added", function()
    hl.exec_cmd("sleep 2; ryoku wm act config.reload")
end)

local wanted = { "eDP-2", "DP-1", "DP-3" }
local live = {}
for _, name in ipairs(wanted) do
    for _, mon in ipairs(hl.get_monitors()) do
        if mon.name == name then
            live[#live + 1] = name
            break
        end
    end
end

if #live > 1 then
    local DESKTOPS = 3
    for ws = 1, DESKTOPS * 10 do
        hl.workspace_rule({
            workspace = tostring(ws),
            monitor = live[((ws - 1) % #live) + 1],
            default = ws <= #live,
        })
    end
end
