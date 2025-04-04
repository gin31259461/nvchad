require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

-- normal mode
map("n", ";", ":", { desc = "CMD enter command mode" })
map("n", "<", "<<", { desc = "indent backward easily" })
map("n", ">", ">>", { desc = "indent forward easily" })
map("n", "<leader>di", "<cmd>Telescope diagnostics<CR>", { desc = "list diagnostics" })
map("n", "<leader>fc", "<cmd>Telescope command_history<CR>", { desc = "list command historys" })
map("n", "<leader>fe", function()
  require("conform").format { lsp_fallback = true }
  vim.cmd "e!"
end, { desc = "general format file and force reload" })
map("n", "<leader>fd", function()
  vim.diagnostic.open_float { border = "rounded" }
end, { desc = "floating diagnostic" })
map("n", "<leader>mp", "<cmd>MarkdownPreview<CR>", { desc = "toggle markdown preview server" })
map("n", "<M-j>", "<cmd>NvimTreeResize +10<CR>", { desc = "increase nvim tree width" })
map("n", "<M-k>", "<cmd>NvimTreeResize -10<CR>", { desc = "decrease nvim tree width" })

-- visual mode
map("x", "<", "<gv", { desc = "indent backward and stay in visual mode" })
map("x", ">", ">gv", { desc = "indent forward and stay in visual mode" })
map("x", "J", ":move '>+1<CR>gv-gv", { desc = "move selected block up and stay in visual mode" })
map("x", "K", ":move '<-2<CR>gv-gv", { desc = "move selected block down and stay in visual mode" })
map("x", "p", '"_dP', { desc = "dont copy replaced text" })

-- insert mode
map("i", "jk", "<ESC>")
