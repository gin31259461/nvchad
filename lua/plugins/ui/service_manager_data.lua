local M = {}

local services = require("config.services")
local state_mod = require("utils.service_state")

-- Returns (status_text, hl_group). Text is never empty. hl reflects the worst state:
--   DiagnosticOk    = installed (and active for LSP)
--   DiagnosticWarn  = installed but idle (LSP), or no mason package
--   DiagnosticError = not installed
function M.entry_status(cat, name, meta)
  local installed = nil -- nil = no mason package
  if meta.mason then
    local ok, reg = pcall(require, "mason-registry")
    if ok then
      local ok2, pkg = pcall(function()
        return reg.get_package(meta.mason)
      end)
      if ok2 and pkg then
        installed = pkg:is_installed()
      end
    end
  end

  local parts = {}
  local hl

  if installed == nil then
    parts[1] = "n/a"
    hl = "DiagnosticWarn"
  elseif installed then
    parts[1] = ""
    hl = "DiagnosticOk"
  else
    parts[1] = ""
    hl = "DiagnosticError"
  end

  if cat == "lsp" then
    if not vim.lsp.is_enabled(name) then
      hl = "DiagnosticError"
    elseif #vim.lsp.get_clients({ name = name }) > 0 then
      hl = "DiagnosticOk"
    else
      hl = "DiagnosticWarn"
    end
  end

  if meta.mason then
    parts[#parts + 1] = "pkg:" .. meta.mason
  end

  parts = vim.tbl_filter(function(s)
    return s ~= ""
  end, parts)

  return table.concat(parts, "  "), hl
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
