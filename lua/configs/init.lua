local M = {}

M.packages = require("configs.packages")

M.icons = {
  misc = {
    dots = "󰇘",
  },
  ft = {
    octo = "",
  },
  dap = {
    Stopped = { "󰁕 ", "DiagnosticWarn", "DapStoppedLine" },
    Breakpoint = " ",
    BreakpointCondition = " ",
    BreakpointRejected = { " ", "DiagnosticError" },
    LogPoint = ".>",
  },
  diagnostics = {
    error = " ",
    warning = " ",
    hint = " ",
    info = " ",
  },
  git = {
    added = " ",
    modified = " ",
    removed = " ",
    unstaged = "󰄱",
    staged = "󰱒",
    unmerged = "",
  },
  fs = {
    default = "󰈚",
    folder = {
      default = "",
      empty = "",
      empty_open = "",
      open = "",
      symlink = "",
    },
  },
  kinds = {
    Array = " ",
    Boolean = "󰨙 ",
    Class = " ",
    Codeium = "󰘦 ",
    Color = " ",
    Control = " ",
    Collapsed = " ",
    Constant = "󰏿 ",
    Constructor = " ",
    Copilot = " ",
    Enum = " ",
    EnumMember = " ",
    Event = " ",
    Field = " ",
    File = " ",
    Folder = " ",
    Function = "󰊕 ",
    Interface = " ",
    Key = " ",
    Keyword = " ",
    Method = "󰊕 ",
    Module = " ",
    Namespace = "󰦮 ",
    Null = " ",
    Number = "󰎠 ",
    Object = " ",
    Operator = " ",
    Package = " ",
    Property = " ",
    Reference = " ",
    Snippet = "󱄽 ",
    String = " ",
    Struct = "󰆼 ",
    Supermaven = " ",
    TabNine = "󰏚 ",
    Text = " ",
    TypeParameter = " ",
    Unit = " ",
    Value = " ",
    Variable = "󰀫 ",
  },
}

M.ignore_msgs = {
  lsp = {
    "is not accessed",
    "Unused local",
  },

  notify = {
    "man.lua",
    "roslyn: %-32000",
    "roslyn: %-30099",
  },
}

return M
