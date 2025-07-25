-- load defaults i.e lua_lsp
require("nvchad.configs.lspconfig").defaults()
dofile(vim.g.base46_cache .. "lsp")
require("nvchad.lsp").diagnostic_config()

local lspconfig_opts = require("plugins.lsp.lspconfig-opt")
local nvlsp = require("nvchad.configs.lspconfig")
local servers = lspconfig_opts.servers
local setup = lspconfig_opts.setup
local capabilities = vim.tbl_deep_extend("force", nvlsp.capabilities, lspconfig_opts.capabilities)

for _, server in ipairs(nvim.configs.packages.lsp_servers) do
  -- copy typescript settings to javascript
  servers["vtsls"].settings.javascript =
    vim.tbl_deep_extend("force", {}, servers["vtsls"].settings.typescript, servers["vtsls"].settings.javascript or {})

  local server_opts = vim.tbl_deep_extend("force", {
    on_init = nvlsp.on_init,
    capabilities = capabilities,
  }, servers[server] or {})

  if setup[server] then
    setup[server]()
  end

  vim.lsp.config(server, server_opts)
  vim.lsp.enable(server)
end
