-- Catppuccin Mocha com acento teal (#94e2d5).
--
-- O Catppuccin não tem um "accent color" único: os destaques da interface
-- (títulos, bordas, busca, picker, statusline) vêm de cores diferentes do
-- palette. Aqui eles são todos puxados para o teal, mantendo o resto do Mocha
-- intacto. Para trocar o acento, basta mudar `teal` abaixo.
local teal = "#94e2d5"

return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    opts = {
      flavour = "mocha",
      background = { light = "latte", dark = "mocha" },
      transparent_background = false,
      integrations = {
        -- lualine: o bloco do modo normal usa azul por padrão; vira teal.
        lualine = {
          mocha = function(colors)
            return {
              normal = {
                a = { bg = colors.teal, fg = colors.base, gui = "bold" },
                b = { bg = colors.surface0, fg = colors.teal },
              },
              inactive = {
                a = { bg = colors.mantle, fg = colors.teal },
              },
            }
          end,
        },
      },
      custom_highlights = function(colors)
        local c = colors
        return {
          -- busca
          Search = { bg = c.teal, fg = c.base },
          IncSearch = { bg = c.teal, fg = c.base },
          CurSearch = { bg = c.teal, fg = c.base, bold = true },

          -- navegação e títulos
          CursorLineNr = { fg = c.teal, bold = true },
          Directory = { fg = c.teal },
          Title = { fg = c.teal, bold = true },

          -- janelas flutuantes (Lazy, Mason, diagnóstico, etc.)
          FloatBorder = { fg = c.teal },
          FloatTitle = { fg = c.teal, bold = true },

          -- picker do snacks
          SnacksPickerMatch = { fg = c.teal, bold = true },
          SnacksPickerSelected = { fg = c.teal },

          -- which-key
          WhichKey = { fg = c.teal },

          -- dashboard (o header "RYOKU" herda de Title/Special)
          SnacksDashboardKey = { fg = c.teal, bold = true },
          SnacksDashboardSpecial = { fg = c.teal },
          SnacksDashboardHeader = { fg = c.teal },

          -- realces de referência do LSP
          LspReferenceText = { bg = c.surface0 },
          LspReferenceRead = { bg = c.surface0 },
          LspReferenceWrite = { bg = c.surface0, underline = true },

          -- seleção de texto
          Visual = { bg = c.surface1 },
        }
      end,
    },
  },

  -- Barra de buffers: o traço do buffer ativo acompanha o acento.
  -- O LazyVim define `highlights` como função (integração do catppuccin), então
  -- embrulhamos essa função em vez de sobrescrevê-la.
  {
    "akinsho/bufferline.nvim",
    optional = true,
    opts = function(_, opts)
      local base = opts.highlights
      opts.highlights = function(defaults)
        local hl = type(base) == "function" and base(defaults) or base or {}
        hl.indicator_selected = vim.tbl_extend("force", hl.indicator_selected or {}, { fg = teal, sp = teal })
        return hl
      end
    end,
  },

  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "catppuccin-mocha" },
  },
}
