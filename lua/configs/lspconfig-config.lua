-- load defaults i.e lua_lsp
require("nvchad.configs.lspconfig").defaults()

local lspconfig = require "lspconfig"
local lspconfig_opts = require "configs.lspconfig-opt"
local nvlsp = require "nvchad.configs.lspconfig"
local pkgs = require("configs.packages").lsp_servers

for _, server in ipairs(pkgs) do
  local servers = lspconfig_opts.servers
  local server_opts = vim.tbl_deep_extend("force", {
    on_init = vim.deepcopy(nvlsp.on_init),
    capabilities = vim.deepcopy(nvlsp.capabilities),
  }, servers[server] or {})

  if lspconfig_opts.setup[server] == nil then
    server_opts = vim.tbl_deep_extend("force", {
      on_attach = vim.deepcopy(nvlsp.on_attach),
    }, server_opts or {})
  end

  lspconfig[server].setup(server_opts)
end

lspconfig.denols.setup {
  on_attach = nvlsp.on_attach,
  on_init = nvlsp.on_init,
  capabilities = nvlsp.capabilities,

  root_dir = lspconfig.util.root_pattern("deno.json", "deno.jsonc"),
}
