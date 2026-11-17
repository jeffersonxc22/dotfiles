-- Aplica o Catppuccin com o palette atual do KDE.
--
-- Fica num módulo próprio porque tanto o LazyVim (na inicialização) quanto o
-- watcher do kdeglobals (lua/config/kde.lua) precisam reaplicar o tema.

local kde = require("config.kde")

local M = {}

function M.apply()
  local ctp = require("catppuccin")
  local state = kde.read()
  local flavour = state and state.flavour or "mocha"
  local mode = state and state.mode or "dark"

  vim.o.background = mode
  ctp.options.color_overrides = kde.overrides(state)
  ctp.compile(flavour)
  -- :colorscheme dispara ColorScheme, então lualine/bufferline se atualizam.
  vim.cmd.colorscheme("catppuccin-" .. flavour)
end

function M.watch()
  kde.watch(M.apply)
end

return M
