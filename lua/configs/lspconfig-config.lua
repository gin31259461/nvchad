-- load defaults i.e lua_lsp
require("nvchad.configs.lspconfig").defaults()

local lspconfig = require "lspconfig"
local nvlsp = require "nvchad.configs.lspconfig"
local pkgs = require("configs.packages").lsp

-- lsps with default config
for _, lsp in ipairs(pkgs) do
  lspconfig[lsp].setup {
    on_attach = nvlsp.on_attach,
    on_init = nvlsp.on_init,
    capabilities = nvlsp.capabilities,
  }
end

lspconfig.denols.setup {
  on_attach = nvlsp.on_attach,
  on_init = nvlsp.on_init,
  capabilities = nvlsp.capabilities,

  root_dir = lspconfig.util.root_pattern("deno.json", "deno.jsonc"),
}

lspconfig.vtsls.setup {
  on_init = nvlsp.on_init,
  capabilities = nvlsp.capabilities,
}

lspconfig.ruff.setup {
  on_init = nvlsp.on_init,
  capabilities = nvlsp.capabilities,
}
