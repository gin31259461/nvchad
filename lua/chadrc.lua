---@module "ui"

local statusline = require("utils.statusline")
local highlights = require("utils.hl")
local config = require("config")
local borders = require("config.borders")

-- https://github.com/NvChad/ui/blob/v2.5/lua/nvconfig.lua
---@type ChadrcConfig
local M = {}

M.base46 = {
  theme = "tokyonight",
  theme_toggle = { "tokyonight", "vscode_light" },

  -- NOTE: merged into ALL integrations (treesitter, lsp, cmp, etc.)
  -- Only affects EXISTING highlight groups, can NOT add new groups.
  -- Uses per-key merge, not full override.
  hl_override = {
    -- NvChad
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

    -- Editor
    Comment = { italic = true },
    ["@comment"] = { italic = true },
    ["@comment.todo"] = {
      bg = "green",
    },

    TreesitterContext = { link = "CursorLine" },
    LspInlayHint = { fg = "#808080", bg = "one_bg", italic = true },

    -- Telescope
    TelescopeMatching = {
      fg = "yellow",
      bg = "NONE",
    },

    TelescopeNormal = { link = "SnacksPickerList" },
    TelescopePromptNormal = { link = "SnacksPickerInput" },
    TelescopeSelection = { link = "SnacksPickerListCursorline" },

    TelescopePromptTitle = { link = "SnacksPickerInputTitle" },
    TelescopePromptPrefix = { link = "SnacksPickerPrompt" },
    TelescopePreviewTitle = { link = "SnacksPickerPreviewTitle" },

    TelescopeBorder = { link = "SnacksPickerBorder" },
    TelescopePromptBorder = { link = "SnacksPickerInputBorder" },
    TelescopeResultsTitle = { link = "SnacksPickerPreviewTitle" },

    -- Misc
    NvimTreeOpenedFolderName = { fg = "green", bold = true },

    -- Window
    NormalFloat = {
      bg = "black",
    },
    FloatBorder = { fg = "blue" },
    FloatTitle = { fg = "blue", bg = "black" },

    CmpPmenu = {
      bg = "black",
    },
    CmpBorder = {
      fg = "grey",
      bg = "NONE",
    },
    CmpDoc = {
      bg = "black",
    },
    CmpDocBorder = {
      fg = "grey",
      bg = "NONE",
    },
  },

  -- NOTE: merged into the "defaults" integration ONLY.
  -- CAN add new highlight groups (not limited to existing ones).
  -- Uses per-key merge, not full override.
  hl_add = {
    CmpGhostText = { link = "Comment", default = true },
    active_context = { fg = "blue" },

    -- Statusline
    ["@statusline.current_file"] = { fg = "#A9B1D6" },
    ["@statusline.symbols"] = { fg = "#ABB2BF", bold = false },
    ["@statusline.text"] = { fg = "#676875" },
    ["@statusline.git"] = { fg = "#646D96", bold = true },
    ["@statusline.copilot"] = { fg = "green" },

    -- Noice
    NoiceCmdlineIcon = { fg = "purple" },
    NoiceCmdlinePopupBorder = { fg = "green" },
    NoiceCmdlinePopup = { bg = "black" },
    NoiceMini = { bg = "black" },
    NoiceCmdlinePopupBorderSearch = { fg = "yellow" },
    NoiceCmdlinePopupTitle = { fg = "blue" },
    NoicePopupBorder = { fg = "blue" },

    -- Snacks input
    -- SnacksInputPrompt = { fg = "purple" },
    -- SnacksInputBorder = { fg = "green" },
    -- SnacksInputTitle = { fg = "green" },

    -- Snacks picker
    SnacksPickerMatch = { link = "TelescopeMatching" },
    SnacksPickerDir = { fg = "#928374" },
    SnacksPickerPathHidden = { fg = "#928374" },

    --
    -- SnacksPickerInput = { link = "TelescopePromptNormal" },
    -- SnacksPickerList = { link = "TelescopeNormal" },
    -- SnacksPickerPreview = { link = "TelescopeNormal" },
    --
    -- SnacksPickerPrompt = { link = "TelescopePromptPrefix" },
    -- SnacksPickerInputTitle = { link = "TelescopePromptTitle" },
    -- SnacksPickerPreviewTitle = { link = "TelescopePreviewTitle" },
    --
    -- SnacksPickerBorder = { fg = "blue", bg = "black2" },
    -- SnacksPickerInputBorder = { fg = "blue", bg = "black2" },
    -- SnacksPickerPreviewBorder = { fg = "blue", bg = "darker_black" },
    -- SnacksPickerListBorder = { fg = "blue", bg = "darker_black" },

    -- DAP
    DapBreakpointColor = { fg = "red" },
  },
}

M.nvdash = {
  load_on_startup = false,
  buttons = {
    {
      txt = "  Explorer",
      keys = "e",
      cmd = ":Neotree action=focus position=float source=filesystem",
    },
    { txt = "  Find File", keys = "f", cmd = ":lua Snacks.picker.files()" },
    {
      txt = "  Recent Files",
      keys = "o",
      cmd = ":lua Snacks.picker.recent()",
    },
    {
      txt = "  Projects",
      keys = "p",
      cmd = ":lua Snacks.picker.projects()",
    },
    {
      txt = "  Config",
      keys = "c",
      cmd = ":lua Snacks.picker.files { cwd = vim.fn.stdpath 'config' }",
    },
    {
      txt = "󱥚  Themes",
      keys = "th",
      cmd = ":lua require('nvchad.themes').open()",
    },
    -- { txt = "  Mappings", keys = "ch", cmd = "NvCheatsheet" },
    { txt = "─", hl = "NvDashFooter", no_gap = true, rep = true },
    {
      txt = function()
        local stats = require("lazy").stats()
        local ms = math.floor(stats.startuptime) .. " ms"
        return "  Loaded "
          .. stats.loaded
          .. "/"
          .. stats.count
          .. " plugins in "
          .. ms
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
    border = borders.default,
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
      mode_override = statusline.mode,
      current_lsp = statusline.current_lsp,
      git_hl = highlights.statusline.git,
      git_override = statusline.git,
      path = statusline.path,
      lsp_symbols = statusline.lsp_symbols,
      break_point = statusline.break_point,
    },
  },

  tabufline = {
    lazyload = false,
    -- order = { "tree_offset", "buffers", "tabs", "btns" },
    order = { "treeOffset", "buffers" },
  },

  cmp = {
    style = "default",
  },
}

M.mason = {
  pkgs = config.packages.mason_ensure_installed,
}

return M
