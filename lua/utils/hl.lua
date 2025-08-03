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
  bg = "#1D1E29",
  bold = true,
  fg = "#646D96",
})

local M = {}

M.statusline = {
  git = "%#@statusline.git#",
  file = "%#@statusline.file.current#",
  text = "%#@statusline.text#",
}

return M
