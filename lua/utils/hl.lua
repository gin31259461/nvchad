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

local set_highlight = vim.api.nvim_set_hl

vim.api.nvim_set_hl(0, "@statusline.current_file", {
  fg = "#A9B1D6",
})

vim.api.nvim_set_hl(0, "@statusline.symbols", {
  fg = "#ABB2BF",
  bold = false,
})

vim.api.nvim_set_hl(0, "@statusline.text", {
  fg = "#676875",
})

vim.api.nvim_set_hl(0, "@statusline.git", {
  fg = "#646D96",
  bold = true,
})

vim.api.nvim_set_hl(0, "TreesitterContext", {
  bg = "#1F2336",
})

vim.api.nvim_set_hl(0, "active_context", {
  fg = "#7AA2F7",
})

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

---Applies dynamic theme-dependent highlights (FloatBorder, LspInlayHint, etc.).
M.setup_dynamic_theme = function()
  ---@type Base30Palette
  local colors = require("base46").get_theme_tb("base_30")
  local color_tool = require("base46.colors")

  set_highlight(0, "FloatBorder", {
    fg = color_tool.change_hex_lightness(colors.blue, 125),
  })

  set_highlight(0, "LspInlayHint", {
    fg = "#808080",
    bg = colors.one_bg,
    italic = true,
  })

  set_highlight(0, "@statusline.copilot", {
    fg = colors.green,
  })
end

---Applies Noice highlight overrides using the current theme palette.
M.setup_noice = function()
  ---@type Base30Palette
  local colors = require("base46").get_theme_tb("base_30")

  set_highlight(0, "NoiceCmdlinePopup", { bg = colors.black })
  set_highlight(0, "NoiceCmdlinePopupBorder", { fg = colors.blue })
  set_highlight(0, "NoiceCmdlinePopupBorderSearch", { fg = colors.yellow })
  set_highlight(0, "NoiceCmdlinePopupTitle", { fg = colors.blue })
  set_highlight(0, "NoiceMini", { bg = colors.black })
  set_highlight(0, "NoicePopupBorder", { fg = colors.blue })
end

---Applies Snacks highlight overrides using the current theme palette.
M.setup_snacks = function()
  ---@type Base30Palette
  local colors = require("base46").get_theme_tb("base_30")

  set_highlight(0, "SnacksPickerMatch", { fg = colors.yellow, bold = true })
  set_highlight(0, "SnacksPickerDir", { fg = colors.grey_fg })

  local notifier_colors = {
    Error = colors.red,
    Warn = colors.yellow,
    Info = colors.green,
    Debug = colors.grey_fg,
    Trace = colors.grey_fg,
  }

  for level, color in pairs(notifier_colors) do
    set_highlight(0, "SnacksNotifierBorder" .. level, { fg = color })
    set_highlight(0, "SnacksNotifierTitle" .. level, { fg = color })
    set_highlight(0, "SnacksNotifierIcon" .. level, { fg = color })
  end
end

---Defines DAP (debugger) sign highlights.
---Refer to: https://github.com/mfussenegger/nvim-dap/issues/1341#issuecomment-2381393267
M.setup_dap = function()
  local colors = require("base46").get_theme_tb("base_30")
  local dap_icons = require("config").icons.dap

  vim.api.nvim_set_hl(0, "DapBreakpointColor", {
    fg = colors.red,
  })

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
  M.setup_dynamic_theme()
  M.setup_dap()
  M.setup_noice()
  M.setup_snacks()

  for k, v in pairs(all_underline_hl) do
    vim.api.nvim_set_hl(0, k, vim.tbl_extend("keep", v, shared_underline_hl))
  end

  for k, v in pairs(all_hl) do
    vim.api.nvim_set_hl(0, k, v)
  end
end

return M
