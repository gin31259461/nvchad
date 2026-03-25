---@module "lspconfig"

---@class Lsp.Config.Servers
---@field [string] vim.lsp.Config | {keys?: LazyKeysSpec[]}

---@class Lsp.Config.Spec
---@field servers Lsp.Config.Servers
---
---default lsp config for all servers
---@field on_init elem_or_list<fun(client: vim.lsp.Client, init_result: lsp.InitializeResult)>
---@field capabilities lsp.ClientCapabilities
---
---@field disable_default_settings {[string]: table}
---@field setup {[string]: function}
---@field diagnostics vim.diagnostic.Opts
---@field inlay_hints {enabled: boolean, exclude: table}
---@field codelens {enabled: boolean, autocmd: boolean}

---@type Lsp.Config.Spec
local spec = require("plugins.lsp.servers.base")

local server_modules = {
  "plugins.lsp.servers.lua_ls",
  "plugins.lsp.servers.typescript",
  "plugins.lsp.servers.python",
  "plugins.lsp.servers.dotnet",
  "plugins.lsp.servers.misc",
}

for _, mod_name in ipairs(server_modules) do
  local mod = require(mod_name)
  spec.servers = vim.tbl_deep_extend("force", spec.servers, mod.servers or {})
  spec.setup   = vim.tbl_deep_extend("force", spec.setup,   mod.setup   or {})
end

return spec
