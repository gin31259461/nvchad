local opt = vim.opt
local o = vim.o
local g = vim.g

o.relativenumber = true

-- https://www.reddit.com/r/neovim/comments/1bs7d6w/how_to_stop_showing_this/
o.shm = o.shm .. "I"
o.fileformats = "unix,dos"

g.snacks_animate = false
g.enable_db_plugins = true
