local M = {}

M.lsp = require "utils.lsp"
M.ft = require "utils.ft"
M.shell = require "utils.shell"
M.root = require "utils.root"
M.configs = require "configs"

---@diagnostic disable: deprecated
M.unpack = table.unpack or unpack

return M
