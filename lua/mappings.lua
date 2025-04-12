require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

-- normal mode
map("n", ";", ":", { desc = "CMD enter command mode" })
map("n", "<", "<<", { desc = "indent backward easily" })
map("n", ">", ">>", { desc = "indent forward easily" })
map("n", "<leader>di", "<cmd>Telescope diagnostics<CR>", { desc = "telescope list diagnostics" })
map("n", "<leader>fc", "<cmd>Telescope command_history<CR>", { desc = "telescope list command historys" })
map("n", "<leader>fd", function()
  vim.diagnostic.open_float { border = "rounded" }
end, { desc = "floating diagnostic" })
map("n", "<leader>mp", "<cmd>MarkdownPreview<CR>", { desc = "toggle markdown preview server" })

-- override nvchad settings
map("n", "<C-n>", "<cmd>Neotree action=show source=last toggle<CR>", { desc = "neotree toggle window" })
map("n", "<leader>e", "<cmd>Neotree action=focus source=last<CR>", { desc = "neotree focus window" })

map("n", "<leader>bb", "<cmd>enew<CR>", { desc = "buffer new" })

-- end override

-- visual mode
map("x", "<", "<gv", { desc = "indent backward and stay in visual mode" })
map("x", ">", ">gv", { desc = "indent forward and stay in visual mode" })
map("x", "J", ":move '>+1<CR>gv-gv", { desc = "move selected block up and stay in visual mode" })
map("x", "K", ":move '<-2<CR>gv-gv", { desc = "move selected block down and stay in visual mode" })
map("x", "p", '"_dP', { desc = "dont copy replaced text" })

-- insert mode
map("i", "jk", "<ESC>")
