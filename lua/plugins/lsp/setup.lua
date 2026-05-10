local ok, err = pcall(function()
  dofile(vim.g.base46_cache .. "lsp")
end)
if not ok then
  vim.notify("[theme] " .. tostring(err), vim.log.levels.WARN)
end

local configs = require("config")
local lspconfig_opts = require("plugins.lsp.config")
local servers = lspconfig_opts.servers
local setup = lspconfig_opts.setup

---@type vim.lsp.Config
local default_lsp_config = {
  on_init = lspconfig_opts.on_init,
  capabilities = lspconfig_opts.capabilities,
}

for _, server in ipairs(configs.packages.lsp_servers) do
  local server_opts = vim.tbl_deep_extend("force", default_lsp_config, servers[server] or {})

  if type(lspconfig_opts.disable_default_settings[server]) == "table" then
    for _, v in ipairs(lspconfig_opts.disable_default_settings[server]) do
      server_opts[v] = nil
    end
  end

  if setup[server] then
    setup[server]()
  end

  vim.lsp.config(server, server_opts)
  vim.lsp.enable(server)
end
