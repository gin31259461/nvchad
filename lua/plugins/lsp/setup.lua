-- load defaults i.e lua_lsp
-- require("nvchad.configs.lspconfig").defaults()
pcall(function()
  dofile(vim.g.base46_cache .. "lsp")
end)

local lspconfig_opts = require("plugins.lsp.config")
local servers = lspconfig_opts.servers
local setup = lspconfig_opts.setup

-- copy typescript settings to javascript
servers["vtsls"].settings.javascript =
  vim.tbl_deep_extend("force", {}, servers["vtsls"].settings.typescript, servers["vtsls"].settings.javascript or {})

---@type vim.lsp.Config
local default_lsp_config = {
  on_init = lspconfig_opts.on_init,
  capabilities = lspconfig_opts.capabilities,
}

for _, server in ipairs(NvChad.config.packages.lsp_servers) do
  local server_opts = vim.tbl_deep_extend("force", default_lsp_config, servers[server] or {})

  if setup[server] then
    setup[server]()
  end

  vim.lsp.config(server, server_opts)
  vim.lsp.enable(server)
end
