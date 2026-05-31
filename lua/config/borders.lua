---@class BordersConfig
local M = {}

-- Default border for standard float windows (cmp, lsp, trouble, which-key, service, term).
M.default = "single"

-- Box-drawing border with CmpBorder highlight (LSP diagnostic float).
M.lsp_diagnostic = {
  { "┌", "CmpBorder" },
  { "─", "CmpBorder" },
  { "┐", "CmpBorder" },
  { "│", "CmpBorder" },
  { "┘", "CmpBorder" },
  { "─", "CmpBorder" },
  { "└", "CmpBorder" },
  { "│", "CmpBorder" },
}

-- Noice uses nui.nvim { style = "..." } format for popup views.
M.noice = {
  lsp = "single",
  cmdline = { style = "single" },
}

-- Snacks style overrides and picker layout borders.
M.snacks = {
  style = "single",
  picker = {
    default = {
      box = "none",
      preview = "solid",
      input = "solid",
      list = "solid",
    },
    select = {
      box = "none",
      input = "solid",
      list = "solid",
    },
    vscode = {
      box = "none",
      input = "solid",
      list = "hpad",
      preview = true,
    },
    vertical = {
      box = "solid",
      input = "bottom",
      list = "solid",
      preview = "top",
    },
  },
}

return M
