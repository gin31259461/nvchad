-- lsp full doc: https://neovim.io/doc/user/lsp.html

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

for _, server in ipairs(Core.config.packages.lsp_servers) do
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

local default_handler = vim.lsp.handlers["textDocument/publishDiagnostics"]

vim.lsp.handlers["textDocument/publishDiagnostics"] = function(err, result, ctx, config)
  if result and result.diagnostics then
    local filtered_diagnostics = {}
    for _, diagnostic in ipairs(result.diagnostics) do
      local should_keep = true
      for _, msg in ipairs(require("configs").ignore_msgs.lsp) do
        if diagnostic.message:find(msg) then
          should_keep = false
          break
        end
      end
      if should_keep then
        table.insert(filtered_diagnostics, diagnostic)
      end
    end
    result.diagnostics = filtered_diagnostics
  end
  default_handler(err, result, ctx, config)
end
