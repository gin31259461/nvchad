vim.api.nvim_set_hl(0, "@statusline.file.current", {
  fg = "#ABB2BF",
  bold = true,
})

vim.api.nvim_set_hl(0, "@statusline.symbols", {
  fg = "#ABB2BF",
  bold = false,
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
M.statusline.current_file = "%#@statusline.file.current#"
M.statusline.text = "%#@statusline.text#"

return M
