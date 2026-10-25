-- Aplica o Catppuccin com o palette atual do DMS.
--
-- Fica num módulo próprio porque tanto o LazyVim (na inicialização) quanto o
-- watcher do DMS (lua/config/dms.lua) precisam reaplicar o tema.

local dms = require("config.dms")

local M = {}

function M.apply()
  local ctp = require("catppuccin")
  local state = dms.read()
  local mode = state and state.mode or "dark"
  local flavour = mode == "light" and "latte" or "mocha"

  vim.o.background = mode
  ctp.options.color_overrides = dms.overrides(state)
  ctp.compile(flavour)
  -- :colorscheme dispara ColorScheme, então lualine/bufferline se atualizam.
  vim.cmd.colorscheme("catppuccin-" .. flavour)
end

function M.watch()
  dms.watch(M.apply)
end

return M
