---@alias ServiceCategory "lsp" | "dap" | "linter" | "formatter"

---@class Service.Meta
---@field ft string[]?
---@field mason string?
---@field note string?

---@class Service.Entry
---@field name string
---@field meta Service.Meta
---@field ft string?
---@field icon_byte integer
---@field status_byte integer
---@field status_hl string

---@class Service.UI
---@field buf integer?
---@field win integer?
---@field category_idx integer
---@field help_open boolean
---@field line_map table<integer, Service.Entry>
---@field live_augroup integer?

---@class Service.FtGroup
---@field ft string
---@field names string[]

---@class Service.CategoryHandler
---@field apply_runtime fun(name: string, meta: Service.Meta, is_enabled: boolean)
---@field entry_status fun(name: string, meta: Service.Meta, installed: boolean?): string?, string?
---@field apply_order (fun(ft: string, enabled_names: string[]))?

---@class Service.Config
---@field max_w integer
---@field min_w integer
---@field max_h integer
---@field min_h integer
---@field col_name integer
---@field col_ft integer
---@field col_status integer
---@field col_tool integer
---@field pad_flat integer
---@field pad_tool integer
---@field service_categories ServiceCategory[]
---@field cat_label table<ServiceCategory, string>

---@type Service.Config
local cfg = {
  max_w = 120,
  min_w = 120,
  max_h = 40,
  min_h = 40,
  col_name = 32,
  col_ft = 32,
  col_status = 64,
  col_tool = 26,
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
