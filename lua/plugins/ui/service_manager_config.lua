---@alias ServiceCategory "lsp" | "dap" | "linter" | "formatter"

local cfg = {
  max_w = 120,
  min_w = 120,
  max_h = 40,
  min_h = 40,
  col_name = 32,
  col_ft = 64,
  col_tool = 26,
  col_status = 10,
  pad_flat = 2,
  pad_tool = 4,
  service_categories = { "lsp", "dap", "linter", "formatter" },
  cat_label = {
    lsp = "LSP",
    dap = "DAP",
    linter = "Linter",
    formatter = "Formatter",
  },
}

return cfg
