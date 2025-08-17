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
local all_underline_hl = {
  Underlined = {
    sp = "#565F89",
    underline = true,
    undercurl = false,
  },
}

local all_hl = {}

---@type vim.api.keyset.highlight
local shared_underline_hl = { undercurl = true, underline = false }

-- TODO: add checking method
local support_undercurl = true

if not support_undercurl then
  shared_underline_hl.undercurl = false
  shared_underline_hl.underline = true
end

local M = {}

M.statusline = {
  git = "%#@statusline.git#",
  file = "%#@statusline.current_file#",
  text = "%#@statusline.text#",
  trouble_text = "%#TroubleStatusline1#",
}

M.setup_diagnostic = function()
  local colors = require("base46").get_theme_tb("base_30")
  local mix_col = require("base46.colors").mix

  local underline_hl = {
    DiagnosticUnderlineError = { sp = colors.red },
    DiagnosticUnderlineWarn = { sp = colors.yellow },
    DiagnosticUnderlineInfo = { sp = colors.green },
    DiagnosticUnderlineHint = { sp = colors.purple },
  }

  local hl = {

    DiagnosticVirtualTextError = { bg = mix_col(colors.red, colors.black, 75), fg = colors.red },
    DiagnosticVirtualTextWarn = { bg = mix_col(colors.yellow, colors.black, 75), fg = colors.yellow },
    DiagnosticVirtualTextInfo = { bg = mix_col(colors.green, colors.black, 75), fg = colors.green },
    DiagnosticVirtualTextHint = { bg = mix_col(colors.purple, colors.black, 75), fg = colors.purple },
  }

  all_underline_hl = vim.tbl_deep_extend("force", all_underline_hl, underline_hl)
  all_hl = vim.tbl_deep_extend("force", all_hl, hl)
end

M.setup = function()
  M.setup_diagnostic()

  for k, v in pairs(all_underline_hl) do
    vim.api.nvim_set_hl(0, k, vim.tbl_extend("keep", v, shared_underline_hl))
  end

  for k, v in pairs(all_hl) do
    vim.api.nvim_set_hl(0, k, v)
  end
end

return M
