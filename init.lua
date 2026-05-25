vim.g.base46_cache = vim.fn.stdpath("data") .. "/nvchad/base46/"
vim.g.mapleader = " "

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  {
    "NvChad/NvChad",
    lazy = false,
    branch = "v2.5",
    import = "nvchad.plugins",
  },
  { import = "plugins" },
}, require("config.lazy"))

require("config.options")
require("nvchad.options")

require("config.autocmds")
require("config.filetypes")
require("nvchad.autocmds")

local fs = require("utils.fs")
for _, cmd_file in ipairs(fs.scandir(fs.config_path .. "/lua/cmds", "file")) do
  require("cmds." .. vim.fn.fnamemodify(cmd_file, ":r"))
end

local ok, err = pcall(function()
  dofile(vim.g.base46_cache .. "defaults")
  dofile(vim.g.base46_cache .. "statusline")
end)
if not ok then
  vim.notify("[theme] " .. tostring(err), vim.log.levels.WARN)
end

require("utils").setup()

vim.schedule(function()
  require("config.keymaps")
end)
