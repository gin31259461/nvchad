local M = {}

local function same_configuration(a, b)
  return a.type == b.type and a.request == b.request and a.name == b.name
end

local function remove_configurations(dap, name)
  for ft, configurations in pairs(dap.configurations or {}) do
    for i = #configurations, 1, -1 do
      if configurations[i].type == name then
        table.remove(configurations, i)
      end
    end
    if vim.tbl_isempty(configurations) then
      dap.configurations[ft] = nil
    end
  end
end

local function add_configurations(dap, name, available_configurations)
  dap.configurations = dap.configurations or {}
  for ft, configurations in pairs(available_configurations or {}) do
    for _, configuration in ipairs(configurations) do
      if configuration.type == name then
        dap.configurations[ft] = dap.configurations[ft] or {}
        local exists = false
        for _, item in ipairs(dap.configurations[ft]) do
          if same_configuration(item, configuration) then
            exists = true
            break
          end
        end
        if not exists then
          table.insert(dap.configurations[ft], vim.deepcopy(configuration))
        end
      end
    end
  end
end

---@param opts Service.ApplyRuntimeOpts
---@return nil
function M.apply_runtime(opts)
  local name, is_enabled = opts.name, opts.is_enabled
  local dap_ok, dap = pcall(require, "dap")
  if not dap_ok then
    return
  end
  local config = require("plugins.debugger.config")
  if is_enabled then
    dap.adapters[name] = config.available_adapters[name]
    add_configurations(dap, name, config.available_configurations)
  else
    dap.adapters[name] = nil
    remove_configurations(dap, name)
  end
end

---@param _opts Service.EntryStatusOpts
---@return string?, string?
function M.entry_status(_opts)
  return nil, nil
end

return M
