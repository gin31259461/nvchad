---@class Base30Palette
---@field white string
---@field black string usually your theme bg
---@field darker_black string 6% darker than black
---@field black2 string 6% lighter than black
---@field one_bg string 10% lighter than black
---@field one_bg2 string 6% lighter than one_bg
---@field one_bg3 string 6% lighter than one_bg2
---@field grey string 40% lighter than black (the % here depends so choose the perfect grey!)
---@field grey_fg string 10% lighter than grey
---@field grey_fg2 string 5% lighter than grey
---@field light_grey string
---@field red string
---@field baby_pink string
---@field pink string
---@field line string 15% lighter than black
---@field green string
---@field vibrant_green string
---@field nord_blue string
---@field blue string
---@field seablue string
---@field yellow string 8% lighter than yellow
---@field sun string
---@field purple string
---@field dark_purple string
---@field teal string
---@field orange string
---@field cyan string
---@field statusline_bg string
---@field lightbg string
---@field pmenu_bg string
---@field folder_bg string

---@type {[string]: vim.api.keyset.highlight}
local all_underline_hl = {
  Underlined = {
    sp = "#565F89",
    underline = true,
    undercurl = false,
  },
}

---@type {[string]: vim.api.keyset.highlight}
local all_hl = {}

---@type vim.api.keyset.highlight
local shared_underline_hl = { undercurl = true, underline = false }

---Detect whether the current terminal supports undercurl.
---GUI front-ends and modern terminal emulators (kitty, WezTerm, iTerm, Ghostty)
---are known to handle curly underlines; for everything else we fall back to
---plain underline.
local is_undercurl_supported = (function()
  if vim.g.neovide or vim.fn.has("gui_running") == 1 then
    return true
  end

  local term = vim.env.TERM or ""
  if term:find("kitty", 1, true) then
    return true
  end

  local known = { WezTerm = true, ["iTerm.app"] = true, ghostty = true }
  if known[vim.env.TERM_PROGRAM] then
    return true
  end

  return false
end)()

if not is_undercurl_supported then
  shared_underline_hl.undercurl = false
  shared_underline_hl.underline = true
end

local M = {}

M.util = {
  ---@param hl string
  get_hl_name_without_syntax = function(hl)
    return hl:gsub("%%#", ""):gsub("#", "")
  end,
}

M.statusline = {
  git = "%#@statusline.git#",
  copilot = "%#@statusline.copilot#",
  current_file = "%#@statusline.current_file#",
  text = "%#@statusline.text#",
  trouble_text = "%#TroubleStatusline1#",
  active_context = "%#active_context#",
}

---Applies diagnostic highlight overrides using the current theme palette.
M.setup_diagnostic = function()
  local colors = require("base46").get_theme_tb("base_30")
  local color_tool = require("base46.colors")

  local underline_hl = {
    DiagnosticUnderlineError = { sp = colors.red },
    DiagnosticUnderlineWarn = { sp = colors.yellow },
    DiagnosticUnderlineInfo = { sp = colors.green },
    DiagnosticUnderlineHint = { sp = colors.purple },
  }

  local virtual_text_highlights = {
    DiagnosticVirtualTextError = {
      bg = color_tool.mix(colors.red, colors.black, 75),
      fg = colors.red,
    },
    DiagnosticVirtualTextWarn = {
      bg = color_tool.mix(colors.yellow, colors.black, 75),
      fg = colors.yellow,
    },
    DiagnosticVirtualTextInfo = {
      bg = color_tool.mix(colors.green, colors.black, 75),
      fg = colors.green,
    },
    DiagnosticVirtualTextHint = {
      bg = color_tool.mix(colors.purple, colors.black, 75),
      fg = colors.purple,
    },
  }

  all_underline_hl =
    vim.tbl_deep_extend("force", all_underline_hl, underline_hl)
  all_hl = vim.tbl_deep_extend("force", all_hl, virtual_text_highlights)
end

---Defines DAP (debugger) sign highlights.
---Refer to: https://github.com/mfussenegger/nvim-dap/issues/1341#issuecomment-2381393267
M.setup_dap = function()
  local colors = require("base46").get_theme_tb("base_30")
  local dap_icons = require("config").icons.dap
  local dap_signs = {}

  for k, v in pairs(dap_icons) do
    if type(v) == "table" then
      local hl_name = "Dap" .. k
      vim.api.nvim_set_hl(0, hl_name, {
        fg = colors.green,
      })
      dap_signs[hl_name] = {
        text = v[1] or "",
        texthl = v[2] or "",
        linehl = v[3] or "",
        numhl = v[4] or "",
      }
    end
  end

  for name, sign in pairs(dap_signs) do
    vim.fn.sign_define(name, sign)
  end
end

---Runs all highlight setup routines (diagnostic, theme, DAP, underline overrides).
M.setup = function()
  M.setup_diagnostic()
  M.setup_dap()

  for k, v in pairs(all_underline_hl) do
    vim.api.nvim_set_hl(0, k, vim.tbl_extend("keep", v, shared_underline_hl))
  end

  for k, v in pairs(all_hl) do
    vim.api.nvim_set_hl(0, k, v)
  end
end

return M
