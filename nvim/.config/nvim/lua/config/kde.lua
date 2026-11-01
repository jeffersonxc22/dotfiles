-- Ponte com o KDE/Plasma.
--
-- O Plasma grava ~/.config/kdeglobals sempre que o esquema de cores, o accent
-- ou as fontes mudam. Lemos esse arquivo para o Neovim acompanhar o tema do
-- desktop:
--   * superfícies e texto -> color_overrides do Catppuccin
--   * accent (Selection) -> grupos de destaque (busca, títulos, picker, lualine)
--
-- A sintaxe continua Catppuccin. Sem kdeglobals (ou sem as seções de cor),
-- tudo cai em Mocha + Sapphire.

local uv = vim.uv or vim.loop

local M = {}

local function config_dir()
  local xdg = vim.env.XDG_CONFIG_HOME
  if xdg and xdg ~= "" then
    return xdg
  end
  return (vim.env.HOME or "~") .. "/.config"
end

M.path = config_dir() .. "/kdeglobals"

local function trim(value)
  return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

--- Lê um INI simples (grupos e pares chave=valor).
local function parse_ini(raw)
  local data = {}
  local group
  for line in raw:gmatch("[^\r\n]+") do
    local header = line:match("^%s*%[([^%]]+)%]%s*$")
    if header then
      group = header
      data[group] = data[group] or {}
    elseif group then
      local key, value = line:match("^%s*([^=]+)%s*=%s*(.-)%s*$")
      if key and value ~= "" then
        data[group][trim(key)] = value
      end
    end
  end
  return data
end

local function clamp(n)
  return math.max(0, math.min(255, math.floor(n + 0.5)))
end

--- Aceita "30, 30, 46" ou "#1e1e2e".
local function rgb(value)
  if not value then
    return nil
  end

  local r, g, b = value:match("^%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*$")
  if r then
    return tonumber(r), tonumber(g), tonumber(b)
  end

  local hex = value:gsub("#", "")
  if #hex == 3 and hex:match("^%x+$") then
    hex = hex:gsub("(.)", "%1%1")
  end
  if #hex == 6 and hex:match("^%x+$") then
    return tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
  end

  return nil
end

local function to_hex(r, g, b)
  return string.format("#%02x%02x%02x", clamp(r), clamp(g), clamp(b))
end

local function color(value, fallback)
  local r, g, b = rgb(value)
  if not r then
    return fallback
  end
  return to_hex(r, g, b)
end

--- Mistura `a` com `b` (t = 0 -> a, t = 1 -> b).
local function mix(a, b, t)
  local ar, ag, ab = rgb(a)
  local br, bg, bb = rgb(b)
  if not ar or not br then
    return a
  end
  return to_hex(ar + (br - ar) * t, ag + (bg - ag) * t, ab + (bb - ab) * t)
end

--- Luminância relativa aproximada (0 = preto, 1 = branco).
local function luminance(hex)
  local r, g, b = rgb(hex)
  if not r then
    return 0
  end
  return (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255
end

--- Descobre o flavour Catppuccin pelo nome do esquema do KDE.
local function flavour_for(name, base)
  local lower = (name or ""):lower()
  if lower:find("mocha", 1, true) then
    return "mocha"
  elseif lower:find("macchiato", 1, true) then
    return "macchiato"
  elseif lower:find("frapp", 1, true) then
    return "frappe"
  elseif lower:find("latte", 1, true) then
    return "latte"
  end

  return luminance(base) > 0.5 and "latte" or "mocha"
end

--- Lê o estado atual do KDE.
---@return { mode: "dark"|"light", flavour: string, palette: table }?
function M.read()
  local file = io.open(M.path, "r")
  if not file then
    return nil
  end
  local raw = file:read("*a")
  file:close()

  local ini = parse_ini(raw)
  local view = ini["Colors:View"] or {}
  local window = ini["Colors:Window"] or {}
  local button = ini["Colors:Button"] or {}
  local selection = ini["Colors:Selection"] or {}
  local wm = ini["WM"] or {}
  local general = ini["General"] or {}

  local base = color(view.BackgroundNormal)
  local text = color(view.ForegroundNormal)
  if not base or not text then
    return nil
  end

  local mantle = color(view.BackgroundAlternate) or color(window.BackgroundNormal) or mix(base, "#000000", 0.15)
  local crust = color(window.BackgroundAlternate) or color(wm.inactiveBackground) or mix(mantle, "#000000", 0.25)
  local surface0 = color(button.BackgroundNormal) or mix(base, text, 0.10)
  local surface1 = color(selection.DecorationHover) or mix(base, text, 0.18)
  local surface2 = mix(surface1, text, 0.15)
  local subtext0 = color(view.ForegroundInactive) or mix(text, base, 0.35)

  local flavour = flavour_for(general.ColorScheme or general.Name, base)
  local mode = flavour == "latte" and "light" or "dark"

  return {
    mode = mode,
    flavour = flavour,
    palette = {
      base = base,
      mantle = mantle,
      crust = crust,
      surface0 = surface0,
      surface1 = surface1,
      surface2 = surface2,
      overlay0 = mix(text, base, 0.55),
      overlay1 = mix(text, base, 0.40),
      overlay2 = mix(text, base, 0.25),
      text = text,
      subtext0 = subtext0,
      subtext1 = mix(text, subtext0, 0.5),
      accent = color(selection.BackgroundNormal) or color(selection.DecorationFocus) or "#74C7EC",
      error = color(view.ForegroundNegative) or "#f38ba8",
      warning = color(view.ForegroundNeutral) or "#f9e2af",
      success = color(view.ForegroundPositive) or "#a6e3a1",
    },
  }
end

--- Overrides de palette do Catppuccin, por flavour.
---@param state table? resultado de M.read()
function M.overrides(state)
  state = state or M.read()
  if not state then
    return {}
  end

  return {
    [state.flavour] = state.palette,
  }
end

--- Accent atual do KDE (Selection), com fallback.
function M.accent(fallback)
  local state = M.read()
  return (state and state.palette and state.palette.accent) or fallback
end

--- Modo atual ("dark" ou "light").
function M.mode(fallback)
  local state = M.read()
  return (state and state.mode) or fallback or "dark"
end

--- Observa kdeglobals e chama `callback` quando a paleta muda.
--- O KDE reescreve o arquivo com rename, então observamos o diretório.
function M.watch(callback)
  if M._watch then
    return
  end

  local handle = uv.new_fs_event()
  local timer = uv.new_timer()
  if not handle or not timer then
    return
  end

  local function stamp()
    local stat = uv.fs_stat(M.path)
    if not stat then
      return "missing"
    end
    return string.format("%d:%d", stat.mtime.sec, stat.mtime.nsec)
  end

  local last = stamp()

  local function on_change()
    local now = stamp()
    if now == last then
      return
    end
    last = now
    vim.schedule(function()
      local ok, err = pcall(callback)
      if not ok then
        vim.notify("Tema do KDE: " .. tostring(err), vim.log.levels.WARN)
      end
    end)
  end

  local dir = vim.fn.fnamemodify(M.path, ":h")
  handle:start(dir, {}, function(err, filename)
    if err then
      return
    end
    if filename and vim.fs.basename(filename) ~= "kdeglobals" then
      return
    end
    timer:stop()
    timer:start(150, 0, on_change)
  end)

  -- fallback: alguns overlays não entregam fs_event
  vim.api.nvim_create_autocmd("FocusGained", {
    group = vim.api.nvim_create_augroup("kde-theme-follow", { clear = true }),
    callback = on_change,
  })

  M._watch = { handle = handle, timer = timer }
end

return M
