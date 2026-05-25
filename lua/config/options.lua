vim.o.relativenumber = true

-- https://www.reddit.com/r/neovim/comments/1bs7d6w/how_to_stop_showing_this/
vim.o.shm = vim.o.shm .. "I"
vim.o.fileformats = "unix,dos"

-- opencode.nvim reloads files via the filesystem; autoread makes those changes visible immediately
vim.o.autoread = true

vim.g.snacks_animate = false
vim.g.ai_cmp = false

-- https://docs.github.com/en/copilot/concepts/completions/code-suggestions
vim.g.copilot_model = "gpt-41-copilot"

vim.o.winborder = "single"
