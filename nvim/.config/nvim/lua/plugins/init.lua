return {
  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- descomente para formatar ao salvar
    opts = require "configs.conform",
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig" -- Centralize aqui a config do gopls como fizemos antes
    end,
  },

  { import = "nvchad.blink.lazyspec" },

  -- My Plugins Here ---
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "gopls",
      },
    },
  },

  {
    "mfussenegger/nvim-dap",
    config = function()
      -- Mappings agora vão no lua/mappings.lua
    end,
  },

  {
    "dreamsofcode-io/nvim-dap-go",
    ft = "go",
    dependencies = "mfussenegger/nvim-dap",
    config = function(_, opts)
      require("dap-go").setup(opts)
    end,
  },
  -- Procure a linha que tem jose-elias-alvarez/null-ls.nvim
{
  "nvimtools/none-ls.nvim", -- ESTA É A MUDANÇA (Substitua o antigo por este)
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  event = "VeryLazy",
  config = function()
    local null_ls = require("null-ls")
    -- Suas configurações de formatting e diagnostics continuam IGUAIS aqui dentro
    null_ls.setup({
      sources = {
        -- Exemplo: null_ls.builtins.formatting.gofmt,
      },
    })
  end,
},

  {
    "olexsmir/gopher.nvim",
    ft = "go",
    config = function(_, opts)
      require("gopher").setup(opts)
    end,
    build = function()
      vim.cmd [[silent! GoInstallDeps]]
    end,
  },

  {
    "Exafunction/codeium.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "hrsh7th/nvim-cmp",
    },
    event = "InsertEnter",
    config = function()
        require("codeium").setup({
            enable_cmp_source = false,
            virtual_text = {
                enabled = true,
                key_bindings = {
                    accept = "<C-g>",
                    next = "<M-]>",
                    prev = "<M-[>",
                }
            }
        })
    end
  },
}
