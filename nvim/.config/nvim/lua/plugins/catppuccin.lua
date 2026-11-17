-- Catppuccin com o chrome vindo do KDE.
--
-- A base é sempre Catppuccin (a sintaxe pastel continua igual). O que vem do
-- kdeglobals (lua/config/kde.lua) é o "chrome": fundo, superfícies, texto e a
-- cor de destaque (accent). Assim, quando você troca o flavour/accent no KDE,
-- o Neovim se ajusta sozinho -- sem reiniciar.
--
-- Sem o KDE (ou sem kdeglobals), tudo cai em Mocha + Sapphire.
local kde = require("config.kde")

local FALLBACK_ACCENT = "#74C7EC"

--- Accent atual: Selection do KDE, com fallback no Sapphire do Catppuccin.
local function accent(fallback)
  return kde.accent(fallback or FALLBACK_ACCENT)
end

-- lualine: o bloco do modo normal usa o accent no lugar do azul padrão.
local function lualine_theme(colors)
  local a = accent(colors.blue)
  return {
    normal = {
      a = { bg = a, fg = colors.base, gui = "bold" },
      b = { bg = colors.surface0, fg = a },
    },
    inactive = {
      a = { bg = colors.mantle, fg = a },
    },
  }
end

local function options()
  return {
    flavour = "auto",
    background = { light = "latte", dark = "mocha" },
    -- Deixa o fundo translúcido aparecer (a opacidade é do kitty).
    transparent_background = true,
    color_overrides = kde.overrides(),
    integrations = {
      lualine = {
        mocha = lualine_theme,
        macchiato = lualine_theme,
        frappe = lualine_theme,
        latte = lualine_theme,
      },
    },
    custom_highlights = function(colors)
      local c = colors
      local a = accent(c.blue)
      return {
        -- busca
        Search = { bg = a, fg = c.base },
        IncSearch = { bg = a, fg = c.base },
        CurSearch = { bg = a, fg = c.base, bold = true },

        -- navegação e títulos
        CursorLineNr = { fg = a, bold = true },
        Directory = { fg = a },
        Title = { fg = a, bold = true },

        -- janelas flutuantes (Lazy, Mason, diagnóstico, etc.)
        FloatBorder = { fg = a },
        FloatTitle = { fg = a, bold = true },

        -- picker do snacks
        SnacksPickerMatch = { fg = a, bold = true },
        SnacksPickerSelected = { fg = a },

        -- which-key
        WhichKey = { fg = a },

        -- dashboard
        SnacksDashboardKey = { fg = a, bold = true },
        SnacksDashboardSpecial = { fg = a },
        SnacksDashboardHeader = { fg = a },

        -- realces de referência do LSP
        LspReferenceText = { bg = c.surface0 },
        LspReferenceRead = { bg = c.surface0 },
        LspReferenceWrite = { bg = c.surface0, underline = true },

        -- seleção de texto
        Visual = { bg = c.surface1 },
      }
    end,
  }
end

-- A aplicação/reaplicação do tema fica em lua/config/colors.lua.
return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    opts = options,
    config = function(_, opts)
      local ctp = require("catppuccin")
      -- recalcula na hora do setup (o KDE pode ter mudado desde o load do spec)
      opts.color_overrides = kde.overrides()
      ctp.setup(opts)
      require("config.colors").watch()
    end,
  },

  -- Barra de buffers: o traço do buffer ativo acompanha o accent.
  -- O LazyVim define `highlights` como função (integração do catppuccin), então
  -- embrulhamos essa função em vez de sobrescrevê-la.
  {
    "akinsho/bufferline.nvim",
    optional = true,
    opts = function(_, opts)
      local base = opts.highlights
      opts.highlights = function(defaults)
        local hl = type(base) == "function" and base(defaults) or base or {}
        local a = accent()
        hl.indicator_selected = vim.tbl_extend("force", hl.indicator_selected or {}, { fg = a, sp = a })
        return hl
      end
    end,
  },

  {
    "LazyVim/LazyVim",
    opts = {
      -- Catppuccin resolve mocha/latte a partir de `background`, que segue o KDE.
      colorscheme = function()
        require("config.colors").apply()
      end,
    },
  },
}
