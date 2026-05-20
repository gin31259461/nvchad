local M = {}

local services = require("config.services")
local state_mod = require("utils.service_state")

local category_handlers = {
  lsp = require("service.category.lsp"),
  dap = require("service.category.dap"),
  linter = require("service.category.linter"),
  formatter = require("service.category.formatter"),
}

function M.entry_status(category, name, meta)
  local installed
  if meta.mason then
    local reg_ok, reg = pcall(require, "mason-registry")
    if reg_ok then
      local pkg_ok, pkg = pcall(reg.get_package, meta.mason)
      if pkg_ok and pkg then
        installed = pkg:is_installed()
      end
    end
  end

  local status_text, highlight_group
  if installed == nil then
    status_text, highlight_group = "n/a", "DiagnosticWarn"
  elseif installed then
    status_text, highlight_group = "installed", "DiagnosticOk"
  else
    status_text, highlight_group = "not installed", "DiagnosticError"
  end

  if installed ~= false then
    local handler = category_handlers[category]
    if handler then
      local refined_text, refined_hl = handler.entry_status(name, meta, installed)
      if refined_text then
        status_text, highlight_group = refined_text, refined_hl
      end
    end
  end

  return status_text, highlight_group
end

function M.build_ft_groups(category)
  local category_services = services[category]
  local saved_orders = state_mod.get()[category .. "_order"]
  local ft_tools = {}

  for name, meta in pairs(category_services) do
    for _, ft in ipairs(meta.ft or {}) do
      ft_tools[ft] = ft_tools[ft] or {}
      ft_tools[ft][name] = true
    end
  end

  local filetypes = vim.tbl_keys(ft_tools)
  table.sort(filetypes)

  local groups = {}
  for _, ft in ipairs(filetypes) do
    local tools_set = ft_tools[ft]
    local saved = saved_orders[ft]
    local ordered = {}

    if saved then
      for _, n in ipairs(saved) do
        if tools_set[n] then
          table.insert(ordered, n)
        end
      end
      for n in pairs(tools_set) do
        if not vim.tbl_contains(ordered, n) then
          table.insert(ordered, n)
        end
      end
    else
      local defaults = services[category .. "_defaults"]
        and services[category .. "_defaults"][ft]
      if defaults then
        for _, n in ipairs(defaults) do
          if tools_set[n] then
            table.insert(ordered, n)
          end
        end
        for n in pairs(tools_set) do
          if not vim.tbl_contains(ordered, n) then
            table.insert(ordered, n)
          end
        end
      else
        for n in pairs(tools_set) do
          table.insert(ordered, n)
        end
        table.sort(ordered)
      end
    end
    table.insert(groups, { ft = ft, names = ordered })
  end
  return groups
end

function M.content_lines(category)
  if category == "lsp" or category == "dap" then
    return vim.tbl_count(services[category])
  end
  local h = 0
  for _, group in ipairs(M.build_ft_groups(category)) do
    h = h + 1 + #group.names
  end
  return h
end

return M
