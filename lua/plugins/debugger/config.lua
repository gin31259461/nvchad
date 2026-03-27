---@alias Dap.Adapters table<string, any>
---@alias Dap.Configurations table<string, table[]>

---@class Dap.Spec
---@field adapters       Dap.Adapters
---@field configurations Dap.Configurations

---@class Dap.Module
---@field adapters?       Dap.Adapters
---@field configurations? Dap.Configurations

local modules = {
  "plugins.debugger.python",
  "plugins.debugger.dotnet",
}

---@type Dap.Spec
local spec = { adapters = {}, configurations = {} }

for _, mod_name in ipairs(modules) do
  local mod = require(mod_name)
  spec.adapters       = vim.tbl_deep_extend("force", spec.adapters,       mod.adapters       or {})
  spec.configurations = vim.tbl_deep_extend("force", spec.configurations, mod.configurations or {})
end

return spec
