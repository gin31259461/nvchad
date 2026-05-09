local M = {}

---Applies diagnostic signs (pre-0.10 compat), virtual-text icon resolution,
---and commits the final config to vim.diagnostic.
---@param opts Lsp.Config.Spec
M.configure = function(opts)
  local configs = require("config")

  if vim.fn.has("nvim-0.10.0") == 0 then
    if type(opts.diagnostics.signs) ~= "boolean" then
      for severity, icon in pairs(opts.diagnostics.signs.text) do
        local name = vim.diagnostic.severity[severity]:lower():gsub("^%l", string.upper)
        name = "DiagnosticSign" .. name
        vim.fn.sign_define(name, { text = icon, texthl = name, numhl = "" })
      end
    end
  end

  if
    type(opts.diagnostics.virtual_text) == "table"
    and opts.diagnostics.virtual_text.prefix == "icons"
  then
    opts.diagnostics.virtual_text.prefix = vim.fn.has("nvim-0.10.0") == 0 and "●"
      or function(diagnostic)
        local icons = configs.icons.diagnostics
        for d, icon in pairs(icons) do
          if diagnostic.severity == vim.diagnostic.severity[d:upper()] then
            return icon
          end
        end
      end
  end

  vim.diagnostic.config(vim.deepcopy(opts.diagnostics))
end

---Installs a middleware on the textDocument/publishDiagnostics handler
---that silently drops diagnostics matching patterns in config.ignore_msgs.lsp.
M.install_filter_middleware = function()
  local default_handler = vim.lsp.handlers["textDocument/publishDiagnostics"]

  vim.lsp.handlers["textDocument/publishDiagnostics"] = function(err, result, ctx, config)
    if result and result.diagnostics then
      local suppressed_patterns = require("config").message_ignored.lsp
      local filtered = {}
      for _, diagnostic in ipairs(result.diagnostics) do
        local suppress = false
        for _, pattern in ipairs(suppressed_patterns) do
          if diagnostic.message:find(pattern) then
            suppress = true
            break
          end
        end
        if not suppress then
          table.insert(filtered, diagnostic)
        end
      end
      result.diagnostics = filtered
    end
    default_handler(err, result, ctx, config)
  end
end

return M
