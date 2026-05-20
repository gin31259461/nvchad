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

local state_mod = require("service.state")

---@type Dap.Spec
local spec = { adapters = {}, configurations = {} }

for _, mod_name in ipairs(modules) do
  local mod = require(mod_name)
  for name, adapter in pairs(mod.adapters or {}) do
    if state_mod.is_enabled("dap", name) then
      spec.adapters[name] = adapter
    end
  end
  spec.configurations =
    vim.tbl_deep_extend("force", spec.configurations, mod.configurations or {})
end

return spec
