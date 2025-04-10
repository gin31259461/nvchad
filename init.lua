vim.g.base46_cache = vim.fn.stdpath "data" .. "/nvchad/base46/"
vim.g.mapleader = " "

-- bootstrap lazy and all plugins
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
end

vim.opt.rtp:prepend(lazypath)

local lazy_config = require "configs.lazy"

_G.nvim = require "utils"

-- load plugins
require("lazy").setup({
  {
    "NvChad/NvChad",
    lazy = false,
    branch = "v2.5",
    import = "nvchad.plugins",
  },

  { import = "plugins" },
}, lazy_config)

-- load theme
dofile(vim.g.base46_cache .. "defaults")
dofile(vim.g.base46_cache .. "statusline")

require "options"

if vim.loop.os_uname().sysname ~= "Linux" then
  vim.cmd "let &shell = has('win32') ? 'powershell' : 'pwsh'"
  vim.cmd "let &shellcmdflag = '-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;'"
  vim.cmd "let &shellredir = '2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode'"
  vim.cmd "let &shellpipe = '2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode'"
  vim.cmd "set shellquote= shellxquote="
end

require "nvchad.autocmds"

vim.schedule(function()
  require "mappings"
end)
