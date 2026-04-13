-- 1. Pega as configurações de elite do NVChad
local nvlsp = require("nvchad.configs.lspconfig")
local on_attach = nvlsp.on_attach
local capabilities = nvlsp.capabilities

-- 2. Servidores Simples (HTML, CSS)
local servers = { "html", "cssls" }

for _, lsp in ipairs(servers) do
  -- FORMA CORRETA 0.11: Define a configuração no registro nativo
  vim.lsp.config(lsp, {
    default_config = {
      on_attach = on_attach,
      capabilities = capabilities,
    },
  })
  -- Ativa o servidor para os arquivos correspondentes
  vim.lsp.enable(lsp)
end

-- 3. Implementação Customizada para Go (gopls)
vim.lsp.config("gopls", {
  default_config = {
    cmd = { "gopls" },
    filetypes = { "go", "gomod", "gowork", "gotmpl" },
    -- Usamos vim.fs.root (nova função nativa do 0.11) para achar o projeto
    root_dir = vim.fs.root(0, { "go.work", "go.mod", ".git" }),
    on_attach = on_attach,
    capabilities = capabilities,
    settings = {
      gopls = {
        completeUnimported = true,
        usePlaceholders = true,
        analyses = { unusedparams = true },
      },
    },
  },
})

-- Ativa o gopls
vim.lsp.enable("gopls")
