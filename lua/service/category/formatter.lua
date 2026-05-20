local M = {}

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

function M.apply_order(ft, enabled_names)
  local conform_ok, conform = pcall(require, "conform")
  if not conform_ok then
    return
  end
  conform.formatters_by_ft[ft] = enabled_names
end

function M.entry_status(_name, _meta, _installed)
  return nil, nil
end

return M
