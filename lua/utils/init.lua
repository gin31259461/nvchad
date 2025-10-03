local LazyUtil = require("lazy.core.util")
local M = {}

setmetatable(M, {
  __index = function(t, k)
    if LazyUtil[k] then
      return LazyUtil[k]
    end
    if k == "lazygit" or k == "toggle" then -- HACK: special case for lazygit
      return M.deprecated[k]()
    end
    ---@diagnostic disable-next-line: no-unknown
    t[k] = require("utils." .. k)
    M.deprecated.decorate(k, t[k])
    return t[k]
  end,
})

M.CREATE_UNDO = vim.api.nvim_replace_termcodes("<c-G>u", true, true, true)
function M.create_undo()
  if vim.api.nvim_get_mode().mode == "i" then
    vim.api.nvim_feedkeys(M.CREATE_UNDO, "n", false)
  end
end

M.lsp = require("utils.lsp")
M.ft = require("utils.ft")
M.shell = require("utils.shell")
M.config = require("configs")
M.fs = require("utils.fs")
M.statusline = require("utils.statusline")
M.cmp = require("utils.cmp")
M.hl = require("utils.hl")
M.ui = require("utils.ui")

---@diagnostic disable: deprecated
M.unpack = table.unpack or unpack

for _, level in ipairs({ "info", "warn", "error" }) do
  M[level] = function(msg, opts)
    opts = opts or {}
    opts.title = opts.title or "NvChad"
    return LazyUtil[level](msg, opts)
  end
end

-- call this setup when all plugins loaded
M.setup = function()
  M.statusline.setup()
  M.shell.setup()
  M.hl.setup()
end

---@param p1 LazySpec[]
---@param p2 LazySpec[]
---@return LazySpec[]
M.merge_plugins_table = function(p1, p2)
  ---@type LazySpec[]
  local result = {}

  for _, v in ipairs(p1) do
    table.insert(result, v)
  end
  for _, v in ipairs(p2) do
    table.insert(result, v)
  end

  return result
end

return M
