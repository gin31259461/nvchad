local M = {}

---@param opts Service.ApplyRuntimeOpts
---@return nil
function M.apply_runtime(opts)
  local name, is_enabled = opts.name, opts.is_enabled
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

---@param _opts Service.EntryStatusOpts
---@return string?, string?
function M.entry_status(_opts)
  return nil, nil
end

return M
