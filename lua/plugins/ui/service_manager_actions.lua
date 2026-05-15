local M = {}

local cfg = require("plugins.ui.service_manager_config")
local data = require("plugins.ui.service_manager_data")
local state_mod = require("utils.service_state")
local ui_utils = require("utils.ui")

local _ui, _tooltip_ns, _render

function M.init(ui, tooltip_ns, render_fn)
  _ui = ui
  _tooltip_ns = tooltip_ns
  _render = render_fn
end

local function current_entry()
  if not _ui.win then
    return nil
  end
  return _ui.line_map[vim.api.nvim_win_get_cursor(_ui.win)[1]]
end

local function install_pkg(pkg_name, on_done)
  if not pkg_name then
    return
  end
  local ok, reg = pcall(require, "mason-registry")
  if not ok then
    return
  end

  if reg.is_installed(pkg_name) then
    vim.notify(pkg_name .. " is already installed", vim.log.levels.INFO)
    if on_done then
      on_done()
    end
    return
  end

  local pkg_ok, pkg = pcall(reg.get_package, pkg_name)
  if pkg_ok and pkg then
    vim.notify("Installing " .. pkg_name .. "…", vim.log.levels.INFO)
    pkg:install():once("closed", function()
      if pkg:is_installed() then
        vim.schedule(function()
          vim.notify(pkg_name .. " installed", vim.log.levels.INFO)
          if on_done then
            on_done()
          end
        end)
      else
        vim.schedule(function()
          vim.notify("Failed to install " .. pkg_name, vim.log.levels.ERROR)
        end)
      end
    end)
  end
end

local function apply_runtime(cat, name, meta, enabled)
  if cat == "lsp" then
    if enabled then
      vim.lsp.enable(name)
      vim.notify(
        name .. " enabled — reopen the file to attach",
        vim.log.levels.INFO
      )
    else
      vim.lsp.enable(name, false)
      for _, client in ipairs(vim.lsp.get_clients({ name = name })) do
        client:stop()
      end
      vim.notify(
        name .. " stopped (takes full effect next session)",
        vim.log.levels.INFO
      )
    end
  elseif cat == "linter" then
    local ok, lint = pcall(require, "lint")
    if not ok then
      return
    end
    for _, ft in ipairs(meta.ft or {}) do
      local list = lint.linters_by_ft[ft] or {}
      lint.linters_by_ft[ft] = list
      if enabled then
        if not vim.tbl_contains(list, name) then
          table.insert(list, name)
        end
      else
        for i = #list, 1, -1 do
          if list[i] == name then
            table.remove(list, i)
          end
        end
      end
    end
  elseif cat == "formatter" then
    local ok, conform = pcall(require, "conform")
    if not ok then
      return
    end
    for _, ft in ipairs(meta.ft or {}) do
      local list = conform.formatters_by_ft[ft] or {}
      conform.formatters_by_ft[ft] = list
      if enabled then
        if not vim.tbl_contains(list, name) then
          table.insert(list, name)
        end
      else
        for i = #list, 1, -1 do
          if list[i] == name then
            table.remove(list, i)
          end
        end
      end
    end
  elseif cat == "dap" then
    local ok, dap = pcall(require, "dap")
    if not ok then
      return
    end
    if enabled then
      dap.adapters[name] = require("plugins.debugger.config").adapters[name]
    else
      dap.adapters[name] = nil
    end
  end
end

function M.show_tooltip_at_cursor()
  local entry = current_entry()
  if not entry or not entry.meta then
    return
  end
  local cat = cfg.service_categories[_ui.cat_idx]

  local install_status = ""
  if entry.meta.mason then
    local ok, reg = pcall(require, "mason-registry")
    if ok then
      local ok2, pkg = pcall(function()
        return reg.get_package(entry.meta.mason)
      end)
      install_status = (ok2 and pkg and pkg:is_installed()) and " ✓" or " ✗"
    end
  end

  local enabled = state_mod.is_enabled(cat, entry.name)
  local icon = enabled and "●" or "○"
  local ft_str = table.concat(entry.meta.ft or {}, "  ")
  local status_text, status_hl = data.entry_status(cat, entry.name, entry.meta)

  local info = {}
  table.insert(info, " " .. icon .. "  " .. entry.name .. " ")
  if ft_str ~= "" then
    table.insert(info, "   ft:     " .. ft_str .. " ")
  end
  if entry.meta.mason then
    table.insert(
      info,
      "   mason:  " .. entry.meta.mason .. install_status .. " "
    )
  end
  table.insert(info, "   status: " .. status_text .. " ")
  if entry.meta.note and entry.meta.note ~= "" then
    table.insert(info, "   note:   " .. entry.meta.note .. " ")
  end

  local max_w = 0
  for _, line in ipairs(info) do
    max_w = math.max(max_w, vim.fn.strdisplaywidth(line))
  end

  local tooltip_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(tooltip_buf, 0, -1, false, info)
  local name_hl = enabled and "DiagnosticOk" or "Comment"
  ui_utils.buf_hl(tooltip_buf, _tooltip_ns, name_hl, 0, 1, 4) -- ● / ○ = 3 bytes at col 1
  for i, line in ipairs(info) do
    if line:match("^   status:") then
      local prefix_len = #"   status: "
      ui_utils.buf_hl(
        tooltip_buf,
        _tooltip_ns,
        status_hl,
        i - 1,
        prefix_len,
        -1
      )
    end
  end

  local cursor = vim.api.nvim_win_get_cursor(_ui.win)
  local cursor_row = cursor[1] - 1 -- 0-indexed
  local float_h = #info + 2 -- +2 for border
  -- show above cursor; fall back to below if not enough room
  local float_row = cursor_row - float_h
  if float_row < 0 then
    float_row = cursor_row + 1
  end

  local tooltip_win = vim.api.nvim_open_win(tooltip_buf, false, {
    relative = "win",
    win = _ui.win,
    row = float_row,
    col = entry.icon_byte,
    width = max_w,
    height = #info,
    style = "minimal",
    border = "single",
    focusable = false,
    zindex = 100,
    noautocmd = true,
  })

  local close = function()
    if vim.api.nvim_win_is_valid(tooltip_win) then
      vim.api.nvim_win_close(tooltip_win, true)
    end
  end
  vim.defer_fn(close, 4000)
  vim.api.nvim_create_autocmd({ "CursorMoved", "WinClosed" }, {
    buffer = _ui.buf,
    once = true,
    callback = close,
  })
end

function M.do_toggle()
  local entry = current_entry()
  if not entry or not entry.meta then
    return
  end
  local category = cfg.service_categories[_ui.cat_idx]
  local new_state = not state_mod.is_enabled(category, entry.name)

  if new_state and entry.meta.mason then
    local ok, reg = pcall(require, "mason-registry")
    if ok then
      local ok2, pkg = pcall(function()
        return reg.get_package(entry.meta.mason)
      end)
      if ok2 and pkg and not pkg:is_installed() then
        install_pkg(entry.meta.mason, function()
          state_mod.set_enabled(category, entry.name, true)
          apply_runtime(category, entry.name, entry.meta, true)
          _render()
        end)
        return
      end
    end
  end

  state_mod.set_enabled(category, entry.name, new_state)
  apply_runtime(category, entry.name, entry.meta, new_state)
  _render()
end

function M.do_install()
  local entry = current_entry()
  if not entry or not entry.meta then
    return
  end
  if not entry.meta.mason then
    vim.notify(
      "No mason package for "
        .. entry.name
        .. (entry.meta.note and (" — " .. entry.meta.note) or ""),
      vim.log.levels.WARN
    )
    return
  end
  install_pkg(entry.meta.mason, _render)
end

function M.do_reorder(dir)
  local entry = current_entry()
  if not entry or not entry.ft then
    return
  end
  local category = cfg.service_categories[_ui.cat_idx]

  local group
  for _, g in ipairs(data.build_ft_groups(category)) do
    if g.ft == entry.ft then
      group = g
      break
    end
  end
  if not group then
    return
  end

  local names = vim.deepcopy(group.names)
  local idx
  for i, n in ipairs(names) do
    if n == entry.name then
      idx = i
      break
    end
  end
  if not idx then
    return
  end

  local new_idx = idx + dir
  if new_idx < 1 or new_idx > #names then
    return
  end

  names[idx], names[new_idx] = names[new_idx], names[idx]

  if category == "linter" or category == "formatter" then
    state_mod.set_order(
      category --[[@as "formatter"|"linter"]],
      entry.ft,
      names
    )
  end

  local enabled_names = vim.tbl_filter(function(n)
    return state_mod.is_enabled(category, n)
  end, names)
  if category == "formatter" then
    local ok, conform = pcall(require, "conform")
    if ok then
      conform.formatters_by_ft[entry.ft] = enabled_names
    end
  else
    local ok, lint = pcall(require, "lint")
    if ok then
      lint.linters_by_ft[entry.ft] = enabled_names
    end
  end

  _render()

  for lnum, e in pairs(_ui.line_map) do
    if e.name == entry.name and e.ft == entry.ft then
      vim.api.nvim_win_set_cursor(_ui.win, { lnum, 0 })
      break
    end
  end
end

function M.switch_tab(idx)
  _ui.cat_idx = idx
  _render()
  local first
  for lnum in pairs(_ui.line_map) do
    first = first and math.min(first, lnum) or lnum
  end
  if first and _ui.win and vim.api.nvim_win_is_valid(_ui.win) then
    vim.api.nvim_win_set_cursor(_ui.win, { first, 0 })
  end
end

return M
