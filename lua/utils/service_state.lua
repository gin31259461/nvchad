local M = {}

local _state = nil
local STATE_PATH = vim.fn.stdpath("data") .. "/service_manager.json"

local function build_defaults()
  local services = require("config.services")
  local defaults = { formatter_order = {}, linter_order = {} }
  for _, cat in ipairs({ "lsp", "dap", "linter", "formatter" }) do
    defaults[cat] = {}
    for name in pairs(services[cat] or {}) do
      defaults[cat][name] = true
    end
  end
  for ft, order in pairs(services.formatter_defaults or {}) do
    defaults.formatter_order[ft] = vim.deepcopy(order)
  end
  for ft, order in pairs(services.linter_defaults or {}) do
    defaults.linter_order[ft] = vim.deepcopy(order)
  end
  return defaults
end

function M.load()
  local f = io.open(STATE_PATH, "r")
  if not f then
    return build_defaults()
  end
  local raw = f:read("*a")
  f:close()
  local ok, decoded = pcall(vim.json.decode, raw)
  if not ok or type(decoded) ~= "table" then
    return build_defaults()
  end

  local state = build_defaults()
  for cat, val in pairs(decoded) do
    if type(val) == "table" then
      if cat == "formatter_order" or cat == "linter_order" then
        for ft, order in pairs(val) do
          state[cat][ft] = order
        end
      elseif state[cat] then
        for name, enabled in pairs(val) do
          if state[cat][name] ~= nil then
            state[cat][name] = enabled
          end
        end
      end
    end
  end
  return state
end

function M.get()
  if not _state then
    _state = M.load()
  end
  return _state
end

function M.save()
  local f = io.open(STATE_PATH, "w")
  if not f then
    vim.notify(
      "ServiceManager: cannot write " .. STATE_PATH,
      vim.log.levels.WARN
    )
    return
  end
  f:write(vim.json.encode(M.get()))
  f:close()
end

function M.is_enabled(cat, name)
  local state = M.get()
  if not state[cat] then
    return true
  end
  local v = state[cat][name]
  return v == nil or v == true
end

function M.set_enabled(cat, name, enabled)
  local state = M.get()
  if state[cat] then
    state[cat][name] = enabled
    M.save()
  end
end

---@param kind "formatter"|"linter"
function M.get_order(kind, ft)
  return M.get()[kind .. "_order"][ft]
end

---@param kind "formatter"|"linter"
function M.set_order(kind, ft, order)
  M.get()[kind .. "_order"][ft] = order
  M.save()
end

return M
