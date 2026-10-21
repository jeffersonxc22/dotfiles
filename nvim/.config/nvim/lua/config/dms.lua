-- Ponte com o DankMaterialShell (DMS).
--
-- O DMS grava ~/.cache/dms/dms-colors.json (matugen) sempre que o tema, o
-- accent ou o wallpaper mudam -- o mesmo arquivo que o shell/GTK leem.
-- Lemos esse arquivo para o Neovim acompanhar o palette do DMS:
--   * superfícies e texto (Material) -> color_overrides do Catppuccin
--   * accent (primary) -> grupos de destaque (busca, títulos, picker, lualine)
--
-- A sintaxe continua Catppuccin (pastel); o que segue o DMS e o "chrome" do
-- editor. Sem o arquivo (DMS ausente), tudo cai no Mocha + teal padrão.

local uv = vim.uv or vim.loop

local M = {}

local function cache_dir()
  local xdg = vim.env.XDG_CACHE_HOME
  if xdg and xdg ~= "" then
    return xdg .. "/dms"
  end
  return (vim.env.HOME or "~") .. "/.cache/dms"
end

M.path = cache_dir() .. "/dms-colors.json"

---@param n number
local function clamp(n)
  return math.max(0, math.min(255, math.floor(n + 0.5)))
end

---@param color string
---@return number?, number?, number?
local function rgb(color)
  local hex = tostring(color or ""):gsub("#", "")
  if #hex == 3 then
    hex = hex:gsub("(.)", "%1%1")
  end
  if #hex ~= 6 then
    return nil
  end
  return tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
end

local function to_hex(r, g, b)
  return string.format("#%02x%02x%02x", clamp(r), clamp(g), clamp(b))
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

local function darken(color, amount)
  return mix(color, "#000000", amount)
end

--- dms-colors guarda o base16 como { dark = ..., light = ..., default = ... }
local function pick16(d16, i, mode)
  local entry = d16["color" .. i]
  if type(entry) == "table" then
    return entry[mode] or entry.default
  end
  return nil
end

--- Normaliza a paleta de um modo (dark/light) para nomes estáveis.
local function normalize(data, mode)
  local c = data.colors and data.colors[mode]
  local d16 = data.dank16 or {}
  if not c and not pick16(d16, 0, mode) then
    return nil
  end

  local bg = (c and (c.background or c.surface)) or pick16(d16, 0, mode)
  local fg = (c and (c.on_background or c.on_surface)) or pick16(d16, 7, mode)
  if not bg or not fg then
    return nil
  end

  -- DMS às vezes devolve surface_container_lowest igual ao background.
  local low = c and (c.surface_container_low or c.surface_dim)
  if not low or low == bg then
    low = darken(bg, 0.35)
  end
  local lowest = c and c.surface_container_lowest
  if not lowest or lowest == bg or lowest == low then
    lowest = darken(low, 0.35)
  end

  local surface0 = (c and (c.surface_container_high or c.surface_bright)) or mix(bg, fg, 0.12)
  local surface1 = (c and c.surface_container_highest) or mix(bg, fg, 0.22)
  local outline = (c and c.outline) or mix(fg, bg, 0.6)

  return {
    mode = mode,
    bg = bg,
    bg_low = low,
    bg_lowest = lowest,
    surface0 = surface0,
    surface1 = surface1,
    surface2 = mix(surface1, fg, 0.18),
    fg = fg,
    subtext1 = (c and c.on_surface) or fg,
    subtext0 = (c and c.on_surface_variant) or mix(fg, bg, 0.35),
    outline = outline,
    accent = (c and c.primary) or pick16(d16, 6, mode) or "#94e2d5",
    secondary = (c and c.secondary) or pick16(d16, 4, mode),
    tertiary = (c and c.tertiary) or pick16(d16, 5, mode),
    error = (c and c.error) or pick16(d16, 1, mode) or "#f38ba8",
    warning = (c and c.warning) or pick16(d16, 3, mode) or "#fab387",
    info = (c and c.info) or (c and c.secondary) or pick16(d16, 4, mode),
  }
end

--- Lê o estado atual do DMS.
---@return { mode: "dark"|"light", palettes: table<string, table>, current: table }?
function M.read()
  local file = io.open(M.path, "r")
  if not file then
    return nil
  end
  local raw = file:read("*a")
  file:close()

  local ok, data = pcall(vim.json.decode, raw)
  if not ok or type(data) ~= "table" then
    return nil
  end

  local dark = normalize(data, "dark")
  local light = normalize(data, "light")
  if not dark and not light then
    return nil
  end

  local mode = data.mode == "light" and "light" or "dark"
  local palettes = { dark = dark, light = light }
  return {
    mode = mode,
    palettes = palettes,
    current = palettes[mode] or dark or light,
  }
end

--- Overrides de palette do Catppuccin, por flavour.
---@param state table? resultado de M.read()
function M.overrides(state)
  state = state or M.read()
  if not state then
    return {}
  end

  local function map(p)
    return {
      base = p.bg,
      mantle = p.bg_low,
      crust = p.bg_lowest,
      surface0 = p.surface0,
      surface1 = p.surface1,
      surface2 = p.surface2,
      text = p.fg,
      subtext1 = p.subtext1,
      subtext0 = p.subtext0,
      overlay0 = p.outline,
      overlay1 = mix(p.outline, p.fg, 0.15),
      overlay2 = mix(p.outline, p.fg, 0.30),
    }
  end

  local overrides = {}
  if state.palettes.dark then
    overrides.mocha = map(state.palettes.dark)
  end
  if state.palettes.light then
    overrides.latte = map(state.palettes.light)
  end
  return overrides
end

--- Accent atual do DMS (primary), com fallback.
function M.accent(fallback)
  local state = M.read()
  return (state and state.current and state.current.accent) or fallback
end

--- Modo atual do DMS ("dark" ou "light").
function M.mode(fallback)
  local state = M.read()
  return (state and state.mode) or fallback or "dark"
end

--- Observa dms-colors.json e chama `callback` quando a paleta muda.
--- O arquivo é reescrito com rename, então observamos o diretório.
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
        vim.notify("DMS theme: " .. tostring(err), vim.log.levels.WARN)
      end
    end)
  end

  local dir = vim.fn.fnamemodify(M.path, ":h")
  handle:start(dir, {}, function(err, filename)
    if err then
      return
    end
    if filename and vim.fs.basename(filename) ~= "dms-colors.json" then
      return
    end
    timer:stop()
    timer:start(150, 0, on_change)
  end)

  -- fallback: alguns gerenciadores de arquivo/overlays não entregam fs_event
  vim.api.nvim_create_autocmd("FocusGained", {
    group = vim.api.nvim_create_augroup("dms-theme-follow", { clear = true }),
    callback = on_change,
  })

  M._watch = { handle = handle, timer = timer }
end

return M
