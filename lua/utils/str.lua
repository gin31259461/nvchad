local M = {}

---@param s string
M.rstrip_slash = function(s)
  -- The pattern '/*$' matches one or more slashes at the end of the string.
  -- It replaces the match with an empty string.
  return s:gsub("/+$", "")
end

return M
