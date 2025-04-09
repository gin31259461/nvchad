local M = {}

---@diagnostic disable: deprecated
M.unpack = table.unpack or unpack

M.ternary = function(cond, t, f)
  if cond then
    return t
  else
    return f
  end
end

return M
