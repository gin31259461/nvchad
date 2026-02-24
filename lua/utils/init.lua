local LazyUtil = require("lazy.core.util")
local M = {}

local modules = {
  lsp = "utils.lsp",
  ft = "utils.ft",
  shell = "utils.shell",
  config = "configs",
  fs = "utils.fs",
  statusline = "utils.statusline",
  cmp = "utils.cmp",
  hl = "utils.hl",
  ui = "utils.ui",
  str = "utils.str",
  table = "utils.table",
}

setmetatable(M, {
  __index = function(t, k)
    if modules[k] then
      local mod = require(modules[k])

      -- add module into cache
      t[k] = mod

      return mod
    end

    if LazyUtil[k] then
      return LazyUtil[k]
    end

    return nil
  end,
})

M.CREATE_UNDO = vim.api.nvim_replace_termcodes("<c-G>u", true, true, true)
function M.create_undo()
  if vim.api.nvim_get_mode().mode == "i" then
    vim.api.nvim_feedkeys(M.CREATE_UNDO, "n", false)
  end
end

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
