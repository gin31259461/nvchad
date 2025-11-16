---@module "ui"

-- https://github.com/NvChad/ui/blob/v2.5/lua/nvconfig.lua
---@type ChadrcConfig
local M = {}

M.base46 = {
  theme = "tokyonight",
  theme_toggle = { "tokyonight", "vscode_light" },

  hl_override = {
    Comment = { italic = true },
    ["@comment"] = { italic = true },
    -- NvimTreeOpenedFolderName = { fg = "green", bold = true },
    St_EmptySpace = {
      bg = "NONE",
    },
    St_CommandModeSep = {
      bg = "NONE",
    },
    St_ConfirmModeSep = {
      bg = "NONE",
    },
    St_InsertModeSep = {
      bg = "NONE",
    },
    St_NTerminalModeSep = {
      bg = "NONE",
    },
    St_NormalModeSep = {
      bg = "NONE",
    },
    St_SelectModeSep = {
      bg = "NONE",
    },
    St_ReplaceModeSep = {
      bg = "NONE",
    },
    St_TerminalModeSep = {
      bg = "NONE",
    },
    St_VisualModeSep = {
      bg = "NONE",
    },
  },

  hl_add = {
    SnacksPickerDir = { fg = "#928374" },
    SnacksPickerPathHidden = { fg = "#928374" },
    CmpGhostText = { link = "Comment", default = true },

    -- SnacksPickerDir = { fg = "light_grey" },
    -- SnacksPickerPathHidden = { fg = "light_grey" },
  },
}

M.nvdash = {
  load_on_startup = false,
  header = require("configs.header").wolf,
  buttons = {
    { txt = "  Explorer", keys = "e", cmd = ":Neotree action=focus position=float source=filesystem" },
    { txt = "  Find File", keys = "f", cmd = ":lua Snacks.picker.files()" },
    { txt = "  Recent Files", keys = "o", cmd = ":lua Snacks.picker.recent()" },
    { txt = "  Projects", keys = "p", cmd = ":lua Snacks.picker.projects()" },
    { txt = "  Config", keys = "c", cmd = ":lua Snacks.picker.files { cwd = vim.fn.stdpath 'config' }" },
    { txt = "󱥚  Themes", keys = "th", cmd = ":lua require('nvchad.themes').open()" },
    -- { txt = "  Mappings", keys = "ch", cmd = "NvCheatsheet" },
    { txt = "─", hl = "NvDashFooter", no_gap = true, rep = true },
    {
      txt = function()
        local stats = require("lazy").stats()
        local ms = math.floor(stats.startuptime) .. " ms"
        return "  Loaded " .. stats.loaded .. "/" .. stats.count .. " plugins in " .. ms
      end,
      hl = "NvDashFooter",
      no_gap = true,
    },

    { txt = "─", hl = "NvDashFooter", no_gap = true, rep = true },
  },
}

M.term = {
  float = {
    relative = "editor",
    row = 0.1,
    col = 0.1,
    width = 0.8,
    height = 0.8,
    border = "single",
  },
}

-- use noice signature so disable nvchad signature
M.lsp = {
  signature = false,
}

M.ui = {

  statusline = {
    theme = "default",
    separator_style = "round",

    -- refer to: https://github.com/NvChad/ui/blob/e0f06a9aa43112e94beca8283516e6804112fb8e/lua/nvchad/stl/utils.lua#L12
    order = {
      "mode_override",
      "git_hl",
      "git_override",
      "break_point",
      "path",
      "lsp_symbols",
      "%=",
      -- "lsp_msg",
      "%=",
      "diagnostics",
      "current_lsp",
      "cwd",
      "cursor",
    },
    modules = {
      mode_override = NvChad.statusline.mode,
      current_lsp = NvChad.statusline.current_lsp,
      git_hl = NvChad.hl.statusline.git,
      git_override = NvChad.statusline.git,
      path = NvChad.statusline.path,
      lsp_symbols = NvChad.statusline.lsp_symbols,
      break_point = NvChad.statusline.break_point,
    },
  },

  -- always load tabufline on startup
  tabufline = {
    lazyload = false,
    -- order = { "tree_offset", "buffers", "tabs", "btns" },
    order = { "tree_offset", "buffers" },
    modules = {
      tree_offset = NvChad.ui.tree_offset,
    },
  },
}

M.mason = {
  pkgs = NvChad.config.packages.mason_ensure_installed,
}

return M
