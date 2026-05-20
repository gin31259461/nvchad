local M = {}

local services = require("config.services")
local state_mod = require("utils.service_state")

---Counts E/W diagnostics and collects messages for `linter_name` across all
---loaded buffers. Queries by nvim-lint's namespace (keyed by linter name) to
---avoid source-name mismatches (e.g. markdownlint-cli2 uses source "markdownlint").
---@param linter_name string
---@return { error_count: integer, warn_count: integer, messages: table[] }
function M.get_linter_diagnostics(linter_name)
  local ns_id = vim.api.nvim_get_namespaces()[linter_name]
  if not ns_id then
    return { error_count = 0, warn_count = 0, messages = {} }
  end

  local error_count = 0
  local warn_count = 0
  local messages = {}

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      for _, diagnostic in
        ipairs(vim.diagnostic.get(bufnr, { namespace = ns_id }))
      do
        if diagnostic.severity == vim.diagnostic.severity.ERROR then
          error_count = error_count + 1
        elseif diagnostic.severity == vim.diagnostic.severity.WARN then
          warn_count = warn_count + 1
        end
        table.insert(messages, {
          file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":t"),
          lnum = diagnostic.lnum + 1,
          col = diagnostic.col + 1,
          severity = diagnostic.severity,
          message = diagnostic.message,
        })
      end
    end
  end

  table.sort(messages, function(a, b)
    if a.severity ~= b.severity then
      return a.severity < b.severity
    end
    if a.file ~= b.file then
      return a.file < b.file
    end
    return a.lnum < b.lnum
  end)

  return {
    error_count = error_count,
    warn_count = warn_count,
    messages = messages,
  }
end

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

  if category == "lsp" and installed ~= false then
    -- Show runtime state rather than just installation status.
    if not vim.lsp.is_enabled(name) then
      status_text = "disabled"
      highlight_group = "DiagnosticError"
    elseif #vim.lsp.get_clients({ name = name }) > 0 then
      status_text = "running"
      highlight_group = "DiagnosticOk"
    else
      status_text = "idle"
      highlight_group = "DiagnosticWarn"
    end
  elseif category == "linter" and installed ~= false then
    -- Show disabled state, run-level errors, or live diagnostic counts.
    if not state_mod.is_enabled(category, name) then
      status_text = "disabled"
      highlight_group = "Comment"
    else
      local logger = require("utils.logger")
      local run_errors = logger.get_entries("linter", name)
      if #run_errors > 0 then
        local latest_error = run_errors[#run_errors]
        if
          latest_error.tags and latest_error.tags.kind == "binary_not_found"
        then
          status_text = "no binary"
        elseif
          latest_error.tags
          and latest_error.tags.kind == "definition_not_found"
        then
          status_text = "missing"
        else
          status_text = "error"
        end
        highlight_group = "DiagnosticError"
      else
        local diagnostic_summary = M.get_linter_diagnostics(name)
        if diagnostic_summary.error_count > 0 then
          status_text = diagnostic_summary.error_count
            .. "E "
            .. diagnostic_summary.warn_count
            .. "W"
          highlight_group = "DiagnosticError"
        elseif diagnostic_summary.warn_count > 0 then
          status_text = diagnostic_summary.warn_count .. "W"
          highlight_group = "DiagnosticWarn"
        else
          status_text = "ok"
          highlight_group = "DiagnosticOk"
        end
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
