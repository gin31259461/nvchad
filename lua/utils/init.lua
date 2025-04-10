local M = {}

M.lsp = require "utils.lsp"
M.ft = require "utils.ft"
M.shell = require "utils.shell"
M.configs = require "configs"

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
