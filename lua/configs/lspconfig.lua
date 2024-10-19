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

-- configuring single server
lspconfig.pylsp.setup {
  settings = {
    pylsp = {
      plugins = {
        pylint = {
          enabled = false,
        },
        pycodestyle = {
          enabled = false,
        },
        pyflakes = {
          enabled = false,
        },
        mccabe = {
          enabled = false,
        },
        autopep8 = {
          enabled = false,
        },
        yapf = {
          enabled = false,
        },
      },
    },
  },
}

lspconfig.denols.setup {
  root_dir = lspconfig.util.root_pattern("deno.json", "deno.jsonc"),
}

lspconfig.vtsls.setup {
  root_dir = lspconfig.util.root_pattern "package.json",
}
