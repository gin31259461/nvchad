local M = {}

---@param name string
---@param _meta Service.Meta
---@param is_enabled boolean
---@return nil
function M.apply_runtime(name, _meta, is_enabled)
  local dap_ok, dap = pcall(require, "dap")
  if not dap_ok then
    return
  end
  if is_enabled then
    dap.adapters[name] = require("plugins.debugger.config").adapters[name]
  else
    dap.adapters[name] = nil
  end
end

---@param _name string
---@param _meta Service.Meta
---@param _installed boolean?
---@return string?, string?
function M.entry_status(_name, _meta, _installed)
  return nil, nil
end

return M
