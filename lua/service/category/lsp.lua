local M = {}

---@param name string
---@param _meta Service.Meta
---@param is_enabled boolean
---@return nil
function M.apply_runtime(name, _meta, is_enabled)
  if is_enabled then
    vim.lsp.enable(name)
    vim.notify(
      name .. " enabled — reopen the file to attach",
      vim.log.levels.INFO
    )
  else
    vim.lsp.enable(name, false)
    for _, client in ipairs(vim.lsp.get_clients({ name = name })) do
      client:stop()
    end
    vim.notify(
      name .. " stopped (takes full effect next session)",
      vim.log.levels.INFO
    )
  end
end

---@param name string
---@param _meta Service.Meta
---@param _installed boolean?
---@return string, string
function M.entry_status(name, _meta, _installed)
  if not vim.lsp.is_enabled(name) then
    return "disabled", "DiagnosticError"
  elseif #vim.lsp.get_clients({ name = name }) > 0 then
    return "running", "DiagnosticOk"
  else
    return "idle", "DiagnosticWarn"
  end
end

return M
