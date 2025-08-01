local M = {}

---@param length integer
---@return string
M.pretty_path = function(length)
  local full_path = vim.fn.expand("%:p")
  if full_path == "" then
    return ""
  end

  -- Normalize and get cwd
  local cwd = vim.fn.getcwd()
  full_path = vim.fs.normalize(full_path)
  cwd = vim.fs.normalize(cwd)

  -- remove cwd prefix
  if full_path:find(cwd, 1, true) == 1 then
    full_path = full_path:sub(#cwd + 2) -- +2 to remove slash
  end

  local sep = package.config:sub(1, 1)
  local parts = vim.split(full_path, "[\\/]", { plain = false })

  if #parts <= length then
    return table.concat(parts, sep)
  end

  local short_parts = { parts[1], "…" }
  vim.list_extend(short_parts, vim.list_slice(parts, #parts - length + 2, #parts))

  return table.concat(short_parts, sep)
end

return M
