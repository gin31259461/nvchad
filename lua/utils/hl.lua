vim.api.nvim_set_hl(0, "@statusline.current_file", {
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

vim.api.nvim_set_hl(0, "TreesitterContext", {
  bg = "#1F2336",
})

local M = {}

M.statusline = {
  git = "%#@statusline.git#",
  file = "%#@statusline.current_file#",
  text = "%#@statusline.text#",
  trouble_text = "%#TroubleStatusline1#",
}

return M
