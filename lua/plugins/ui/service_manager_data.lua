local M = {}

local services = require("config.services")
local state_mod = require("utils.service_state")

function M.entry_status(cat, name, meta)
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

  if cat == "lsp" then
    if not vim.lsp.is_enabled(name) then
      highlight_group = "DiagnosticError"
    elseif #vim.lsp.get_clients({ name = name }) > 0 then
      highlight_group = "DiagnosticOk"
    else
      highlight_group = "DiagnosticWarn"
    end
  end

  return status_text, highlight_group
end

function M.build_ft_groups(cat)
  local cat_svc = services[cat]
  local saved_ords = state_mod.get()[cat .. "_order"]
  local ft_tools = {}

  for name, meta in pairs(cat_svc) do
    for _, ft in ipairs(meta.ft or {}) do
      ft_tools[ft] = ft_tools[ft] or {}
      ft_tools[ft][name] = true
    end
  end

  local fts = vim.tbl_keys(ft_tools)
  table.sort(fts)

  local groups = {}
  for _, ft in ipairs(fts) do
    local tools_set = ft_tools[ft]
    local saved = saved_ords[ft]
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
      local defs = services[cat .. "_defaults"]
        and services[cat .. "_defaults"][ft]
      if defs then
        for _, n in ipairs(defs) do
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

function M.content_lines(cat)
  if cat == "lsp" or cat == "dap" then
    return vim.tbl_count(services[cat])
  end
  local h = 0
  for _, g in ipairs(M.build_ft_groups(cat)) do
    h = h + 1 + #g.names
  end
  return h
end

return M
