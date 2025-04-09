-- load defaults i.e lua_lsp
require("nvchad.configs.lspconfig").defaults()

local lspconfig = require "lspconfig"
local lspconfig_opt = require "configs.lspconfig-opt"
local nvlsp = require "nvchad.configs.lspconfig"
local pkgs = require("configs.packages").lsp_servers

for _, lsp_server_name in ipairs(pkgs) do
  if lspconfig_opt.setup[lsp_server_name] ~= nil then
    lspconfig[lsp_server_name].setup {
      on_init = nvlsp.on_init,
      capabilities = nvlsp.capabilities,
    }
  else
    lspconfig[lsp_server_name].setup {
      on_init = nvlsp.on_init,
      capabilities = nvlsp.capabilities,
      on_attach = nvlsp.on_attach,
    }
  end
end

lspconfig.denols.setup {
  on_attach = nvlsp.on_attach,
  on_init = nvlsp.on_init,
  capabilities = nvlsp.capabilities,

  root_dir = lspconfig.util.root_pattern("deno.json", "deno.jsonc"),
}
