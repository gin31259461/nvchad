vim.g.base46_cache = vim.fn.stdpath("data") .. "/nvchad/base46/"
vim.g.mapleader = " "

-- 1. Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system({ "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- 2. Setup Plugins
-- This adds plugins like NvChad to the RTP
require("lazy").setup({
  {
    "NvChad/NvChad",
    lazy = false,
    branch = "v2.5",
    import = "nvchad.plugins",
  },
  { import = "plugins" },
}, require("config.lazy"))

-- 3. Load Options (Custom and NvChad)
require("config.options")
require("nvchad.options")

-- 4. Load Autocmds (Custom and NvChad)
require("config.autocmds")
require("nvchad.autocmds")

-- 5. Setup utilities
require("utils").setup()

-- 6. Load Theme
local ok, err = pcall(function()
  dofile(vim.g.base46_cache .. "defaults")
  dofile(vim.g.base46_cache .. "statusline")
end)
if not ok then
  vim.notify("[theme] " .. tostring(err), vim.log.levels.WARN)
end

-- 7. Keymaps (Scheduled for better startup)
vim.schedule(function()
  require("config.keymaps")
end)
