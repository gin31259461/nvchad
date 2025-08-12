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

M.setup_diagnostic_underline = function()
  -- TODO: add checking method
  local support_undercurl = true
  local colors = require("base46").get_theme_tb("base_30")
  -- local mix_col = require("base46.colors").mix

  local highlights = {
    DiagnosticUnderlineError = { sp = colors.red },
    DiagnosticUnderlineWarn = { sp = colors.yellow },
    DiagnosticUnderlineInfo = { sp = colors.green },
    DiagnosticUnderlineHint = { sp = colors.purple },
  }

  ---@type vim.api.keyset.highlight
  local shared_hl = {}

  if support_undercurl then
    shared_hl.undercurl = true
  else
    shared_hl.underline = true
  end

  for k, v in pairs(highlights) do
    vim.api.nvim_set_hl(0, k, vim.tbl_extend("force", v, shared_hl))
  end
end

M.setup = function()
  M.setup_diagnostic_underline()
end

return M
