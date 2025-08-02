local M = {}

require("utils.hl")

M.lsp = require("utils.lsp")
M.ft = require("utils.ft")
M.shell = require("utils.shell")
M.config = require("configs")
M.root = require("utils.root")
M.statusline = require("utils.statusline")
M.hl = require("utils.hl")

---@diagnostic disable: deprecated
M.unpack = table.unpack or unpack

return M
