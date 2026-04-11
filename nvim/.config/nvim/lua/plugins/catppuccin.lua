return {
  {
    "catppuccin/nvim",
    lazy = false,
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        transparent_background = true,
        color_overrides = {
          mocha = {
            mauve = "#74c7ec", -- redireciona mauve → sapphire
          },
        },
      })
      vim.cmd.colorscheme "catppuccin-mocha"
    end
  }
}
