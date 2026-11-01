-- Efeitos de UI: animações, dashboard e notificações.
--
-- mini.animate cuida de scroll/resize/janelas. O cursor fica de fora: o efeito
-- de rastro/stretch vem do kitty (cursor_trail), não do Neovim.
local dashboard_header = [[

███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝

]]

local dashboard_keys = {
  { key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
  { key = "n", desc = "New File", action = ":ene | startinsert" },
  { key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
  { key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
  {
    key = "c",
    desc = "Config",
    action = ":lua Snacks.dashboard.pick('files', { cwd = vim.fn.stdpath('config') })",
  },
  { key = "s", desc = "Restore Session", section = "session" },
  { key = "x", desc = "Lazy Extras", action = ":LazyExtras" },
  { key = "l", desc = "Lazy", action = ":Lazy" },
  { key = "q", desc = "Quit", action = ":qa" },
}

return {
  {
    "nvim-mini/mini.animate",
    event = "VeryLazy",
    opts = {
      -- O rastro do cursor é do kitty; animar de novo aqui duplica o efeito.
      cursor = { enable = false },
      -- Snacks é responsável pelo scroll; evita duas animações concorrentes.
      scroll = { enable = false },
      resize = { enable = true },
      open = { enable = true },
      close = { enable = true },
    },
  },

  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      opts.scroll = vim.tbl_deep_extend("force", opts.scroll or {}, { enabled = true })
      opts.indent = vim.tbl_deep_extend("force", opts.indent or {}, { enabled = true })

      -- O notifier padrão do snacks é substituído pelo nvim-notify abaixo.
      opts.notifier = vim.tbl_deep_extend("force", opts.notifier or {}, { enabled = false })

      local dashboard = opts.dashboard or {}
      local preset = dashboard.preset or {}
      preset.pick = function(cmd, pick_opts)
        return LazyVim.pick(cmd, pick_opts)()
      end
      preset.header = dashboard_header
      preset.keys = dashboard_keys
      dashboard.preset = preset
      opts.dashboard = dashboard

      return opts
    end,
  },

  {
    "rcarriga/nvim-notify",
    event = "VeryLazy",
    opts = {
      timeout = 3000,
      max_width = function()
        return math.floor(vim.o.columns * 0.6)
      end,
      max_height = function()
        return math.floor(vim.o.lines * 0.6)
      end,
      render = "wrapped-compact",
      stages = "fade_in_slide_out",
    },
    config = function(_, opts)
      local notify = require("notify")
      notify.setup(opts)
      vim.notify = notify
    end,
  },
}
