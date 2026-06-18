local M = {}

local order = require("service.order")

---@param opts Service.ApplyRuntimeOpts
---@return nil
function M.apply_runtime(opts)
  local name, meta, is_enabled = opts.name, opts.meta, opts.is_enabled
  local conform_ok, conform = pcall(require, "conform")
  if not conform_ok then
    return
  end
  for _, ft in ipairs(meta.ft or {}) do
    local list = conform.formatters_by_ft[ft] or {}
    if is_enabled then
      if not vim.tbl_contains(list, name) then
        table.insert(list, name)
      end
    else
      for i = #list, 1, -1 do
        if list[i] == name then
          table.remove(list, i)
        end
      end
    end
    conform.formatters_by_ft[ft] =
      order.enabled_names_for_ft("formatter", ft, list)
  end
end

---@param opts Service.ApplyOrderOpts
---@return nil
function M.apply_order(opts)
  local ft, enabled_names = opts.ft, opts.enabled_names
  local conform_ok, conform = pcall(require, "conform")
  if not conform_ok then
    return
  end
  conform.formatters_by_ft[ft] = enabled_names
end

---@param _opts Service.EntryStatusOpts
---@return string?, string?
function M.entry_status(_opts)
  return nil, nil
end

return M
