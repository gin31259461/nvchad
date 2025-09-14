-- nvchad default mappings
-- require "nvchad.mappings"

local map = vim.keymap.set

-------------------- movement --------------------
map("i", "<C-j>", "<Down>", { desc = "move down" })
map("i", "<C-k>", "<Up>", { desc = "move up" })
map("i", "<C-h>", "<Left>", { desc = "move left" })
map("i", "<C-l>", "<Right>", { desc = "move right" })

map("n", "<C-h>", "<C-w>h", { desc = "switch window left" })
map("n", "<C-l>", "<C-w>l", { desc = "switch window right" })
map("n", "<C-j>", "<C-w>j", { desc = "switch window down" })
map("n", "<C-k>", "<C-w>k", { desc = "switch window up" })

-- map("i", "<C-e>", "<End>", { desc = "move end of line" })
-- map("i", "<C-b>", "<ESC>^i", { desc = "move beginning of line" })

-------------------- file --------------------
map("n", "<C-s>", "<cmd>w<CR>", { desc = "general save file" })
map("n", "<C-c>", "<cmd>%y+<CR>", { desc = "general copy whole file" })
map({ "n", "x" }, "<leader>fm", function()
  require("conform").format({ lsp_fallback = true })
end, { desc = "Format file" })

-------------------- navigation & buffer --------------------
map("n", "<leader>bb", "<cmd>enew<CR>", { desc = "buffer new" })

map("n", "<tab>", function()
  require("nvchad.tabufline").next()
end, { desc = "buffer goto next" })
map("n", "<S-tab>", function()
  require("nvchad.tabufline").prev()
end, { desc = "buffer goto prev" })

map("n", "<leader>x", function()
  require("nvchad.tabufline").close_buffer()
end, { desc = "buffer close" })

map("n", "<leader>bc", "<cmd>%bd|e#<cr>", { desc = "buffer close" })

-- nvimtree [not used]
-- map("n", "<C-n>", "<cmd>NvimTreeToggle<CR>", { desc = "nvimtree toggle window" })
-- map("n", "<leader>e", "<cmd>NvimTreeFocus<CR>", { desc = "nvimtree focus window" })

-------------------- terminal --------------------
map("t", "<C-x>", "<C-\\><C-N>", { desc = "terminal escape terminal mode" })

-- new terminals
map("n", "<leader>h", function()
  require("nvchad.term").new({ pos = "sp" })
end, { desc = "terminal new horizontal term" })

map("n", "<leader>v", function()
  require("nvchad.term").new({ pos = "vsp" })
end, { desc = "terminal new vertical term" })

-- toggleable
map({ "n", "t" }, "<M-v>", function()
  if NvChad.ui.check_toggle_nvterm() then
    require("nvchad.term").toggle({ pos = "vsp", id = "vtoggleTerm" })
  end
end, { desc = "terminal toggleable vertical term" })

map({ "n", "t" }, "<M-h>", function()
  if NvChad.ui.check_toggle_nvterm() then
    require("nvchad.term").toggle({ pos = "sp", id = "htoggleTerm" })
  end
end, { desc = "terminal toggleable horizontal term" })

map({ "n", "t" }, "<M-i>", function()
  if NvChad.ui.check_toggle_nvterm() then
    require("nvchad.term").toggle({ pos = "float", id = "floatTerm" })
  end
end, { desc = "terminal toggle floating term" })

-------------------- whick key --------------------
map("n", "<leader>wK", "<cmd>WhichKey <CR>", { desc = "whichkey all keymaps" })
map("n", "<leader>wk", function()
  vim.cmd("WhichKey " .. vim.fn.input("WhichKey: "))
end, { desc = "whichkey query lookup" })

-------------------- QoL --------------------
map("n", ";", ":", { desc = "CMD enter command mode" })
map("n", "<", "<<", { desc = "indent backward easily" })
map("n", ">", ">>", { desc = "indent forward easily" })
map("x", "<", "<gv", { desc = "indent backward and stay in visual mode" })
map("x", ">", ">gv", { desc = "indent forward and stay in visual mode" })
map("x", "J", ":move '>+1<CR>gv-gv", { desc = "move selected block up and stay in visual mode" })
map("x", "K", ":move '<-2<CR>gv-gv", { desc = "move selected block down and stay in visual mode" })
map("x", "p", '"_dP', { desc = "dont copy replaced text" })
map("n", "<Esc>", "<cmd>noh<CR>", { desc = "general clear highlights" })
map("i", "jk", "<ESC>")

-- comment
map("n", "<leader>/", "gcc", { desc = "toggle comment", remap = true })
map("v", "<leader>/", "gc", { desc = "toggle comment", remap = true })

-------------------- tab --------------------
map("n", "<leader>tN", "<cmd>tabnew<cr>", { desc = "CMD enter command mode" })
map("n", "<leader>tn", "<cmd>tabn<cr>", { desc = "CMD enter command mode" })
map("n", "<leader>tp", "<cmd>tabp<cr>", { desc = "CMD enter command mode" })
map("n", "<leader>tx", "<cmd>tabclose<cr>", { desc = "CMD enter command mode" })

-------------------- diagnostic --------------------
map("n", "<leader>fd", function()
  vim.diagnostic.open_float({ border = "single" })
end, { desc = "floating diagnostic" })

-- map("n", "<leader>ds", vim.diagnostic.setloclist, { desc = "LSP diagnostic loclist" })

-------------------- other --------------------
map("n", "<leader>mp", "<cmd>MarkdownPreview<CR>", { desc = "toggle markdown preview server" })
map("n", "<leader>ch", "<cmd>NvCheatsheet<CR>", { desc = "toggle nvcheatsheet" })

map("n", "<leader>th", function()
  require("nvchad.themes").open()
end, { desc = "telescope nvchad themes" })

-- map("n", "<leader>n", "<cmd>set nu!<CR>", { desc = "toggle line number" })
-- map("n", "<leader>rn", "<cmd>set rnu!<CR>", { desc = "toggle relative number" })
