local M = {}

---@param name string
---@param meta Service.Meta
---@param is_enabled boolean
---@return nil
function M.apply_runtime(name, meta, is_enabled)
  local conform_ok, conform = pcall(require, "conform")
  if not conform_ok then
    return
  end
  for _, ft in ipairs(meta.ft or {}) do
    local list = conform.formatters_by_ft[ft] or {}
    conform.formatters_by_ft[ft] = list
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
  end
end

---@param ft string
---@param enabled_names string[]
---@return nil
function M.apply_order(ft, enabled_names)
  local conform_ok, conform = pcall(require, "conform")
  if not conform_ok then
    return
  end
  conform.formatters_by_ft[ft] = enabled_names
end

---@param _name string
---@param _meta Service.Meta
---@param _installed boolean?
---@return string?, string?
function M.entry_status(_name, _meta, _installed)
  return nil, nil
end

return M
