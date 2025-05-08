local M = {}

M.is_linux = function()
  return vim.uv.os_uname().sysname:find "Linux" ~= nil
end

M.is_win = function()
  return vim.uv.os_uname().sysname:find "Windows" ~= nil
end

return M
