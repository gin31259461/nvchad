require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

-- normal mode
map("n", ";", ":", { desc = "CMD enter command mode" })
map("n", "<", "<<", { desc = "indent backward easily" })
map("n", ">", ">>", { desc = "indent forward easily" })
map("n", "<leader>di", "<cmd> Telescope diagnostics <CR>", { desc = "list diagnostics" })
map("n", "<leader>fc", "<cmd> Telescope command_history <CR>", { desc = "list command historys" })
map("n", "<leader>fd", function()
  vim.diagnostic.open_float { border = "rounded" }
end, { desc = "floating diagnostic" })

-- visual mode
map("x", "<", "<gv", { desc = "indent backward and stay in visual mode" })
map("x", ">", ">gv", { desc = "indent forward and stay in visual mode" })
map("x", "J", ":move '>+1<CR>gv-gv", { desc = "move selected block up and stay in visual mode" })
map("x", "K", ":move '<-2<CR>gv-gv", { desc = "move selected block down and stay in visual mode" })

-- insert mode
map("i", "jk", "<ESC>")

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
