vim.api.nvim_set_hl(0, "@statusline.current_file", {
  fg = "#ABB2BF",
})

vim.api.nvim_set_hl(0, "@statusline.text", {
  fg = "#676875",
})

vim.api.nvim_set_hl(0, "@statusline.git", {
  fg = "#ABB2BF",
  -- bold = true,
})

local M = {}

M.statusline = {}
M.statusline.git = "%#@statusline.git#"
M.statusline.current_file = "%#@statusline.current_file#"
M.statusline.text = "%#@statusline.text#"

return M
