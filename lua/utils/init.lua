local M = {}

M.lsp = require("utils.lsp")
M.ft = require("utils.ft")
M.shell = require("utils.shell")
M.configs = require("configs")
M.root = require("utils.root")

---@diagnostic disable: deprecated
M.unpack = table.unpack or unpack

return M
