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

---@type {[string]: vim.api.keyset.highlight}
local underline_highlights = {
  Underlined = {
    sp = "#565F89",
    underline = false,
    undercurl = true,
  },
}

---@type vim.api.keyset.highlight
local shared_hl = { undercurl = true, underline = false }

-- TODO: add checking method
local support_undercurl = true

if not support_undercurl then
  shared_hl.undercurl = false
  shared_hl.underline = true
end

local M = {}

M.statusline = {
  git = "%#@statusline.git#",
  file = "%#@statusline.current_file#",
  text = "%#@statusline.text#",
  trouble_text = "%#TroubleStatusline1#",
}

M.setup_diagnostic_underline = function()
  local colors = require("base46").get_theme_tb("base_30")
  -- local mix_col = require("base46.colors").mix

  local highlights = {
    DiagnosticUnderlineError = { sp = colors.red },
    DiagnosticUnderlineWarn = { sp = colors.yellow },
    DiagnosticUnderlineInfo = { sp = colors.green },
    DiagnosticUnderlineHint = { sp = colors.purple },
  }

  underline_highlights = vim.tbl_deep_extend("keep", underline_highlights, highlights)
end

M.setup = function()
  M.setup_diagnostic_underline()

  for k, v in pairs(underline_highlights) do
    vim.api.nvim_set_hl(0, k, vim.tbl_extend("keep", v, shared_hl))
  end
end

return M
