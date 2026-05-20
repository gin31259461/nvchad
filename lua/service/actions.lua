local M = {}

local cfg = require("service.config")
local data = require("service.data")
local state_mod = require("service.state")
local ui_utils = require("utils.ui")
local logger = require("utils.logger")

local category_handlers = {
  lsp = require("service.category.lsp"),
  dap = require("service.category.dap"),
  linter = require("service.category.linter"),
  formatter = require("service.category.formatter"),
}

---@class Service.Actions.State
---@field ui Service.UI?
---@field tooltip_ns integer?
---@field render (fun())?

---@type Service.Actions.State
local _state = { ui = nil, tooltip_ns = nil, render = nil }

---@param opts { ui: Service.UI, tooltip_ns: integer, render: fun() }
function M.init(opts)
  _state.ui = opts.ui
  _state.tooltip_ns = opts.tooltip_ns
  _state.render = opts.render
end

---@return Service.Entry?
local function current_entry()
  if not _state.ui.win then
    return nil
  end
  return _state.ui.line_map[vim.api.nvim_win_get_cursor(_state.ui.win)[1]]
end

---@param pkg_name string?
---@param on_done (fun())?
local function install_pkg(pkg_name, on_done)
  if not pkg_name then
    return
  end
  local reg_ok, reg = pcall(require, "mason-registry")
  if not reg_ok then
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

local MAX_TOOLTIP_MESSAGES = 8
local TOOLTIP_MSG_MAX_W = 70

---@return nil
function M.show_tooltip_at_cursor()
  local entry = current_entry()
  if not entry or not entry.meta then
    return
  end
  local category = cfg.service_categories[_state.ui.category_idx]

  local install_status = ""
  if entry.meta.mason then
    local reg_ok, reg = pcall(require, "mason-registry")
    if reg_ok then
      local pkg_ok, pkg = pcall(reg.get_package, entry.meta.mason)
      install_status = (pkg_ok and pkg and pkg:is_installed()) and " ✓"
        or " ✗"
    end
  end

  local is_entry_enabled = state_mod.is_enabled(category, entry.name)
  local icon = is_entry_enabled and "●" or "○"
  local ft_str = table.concat(entry.meta.ft or {}, ", ")
  local status_text, status_hl =
    data.entry_status(category, entry.name, entry.meta)

  local tooltip_lines = {}
  table.insert(tooltip_lines, " " .. icon .. "  " .. entry.name .. " ")
  if ft_str ~= "" then
    table.insert(tooltip_lines, "   ft:     " .. ft_str .. " ")
  end
  if entry.meta.mason then
    table.insert(
      tooltip_lines,
      "   mason:  " .. entry.meta.mason .. install_status .. " "
    )
  end
  table.insert(tooltip_lines, "   status: " .. status_text .. " ")
  if entry.meta.note and entry.meta.note ~= "" then
    table.insert(tooltip_lines, "   note:   " .. entry.meta.note .. " ")
  end

  -- For linters, append run-level errors then live diagnostic messages.
  if category == "linter" and is_entry_enabled then
    local run_errors = logger.get_entries("linter", entry.name)
    if #run_errors > 0 then
      table.insert(
        tooltip_lines,
        "   ──────────────────────────── "
      )
      for _, run_error in ipairs(run_errors) do
        local level_char = run_error.level == "ERROR" and "E" or "W"
        local text = string.format("   %s  %s ", level_char, run_error.message)
        if vim.fn.strdisplaywidth(text) > TOOLTIP_MSG_MAX_W then
          text = text:sub(1, TOOLTIP_MSG_MAX_W - 1) .. "… "
        end
        table.insert(tooltip_lines, text)
      end
    end

    local diagnostic_summary =
      category_handlers.linter.get_linter_diagnostics(entry.name)
    if #diagnostic_summary.messages > 0 then
      table.insert(
        tooltip_lines,
        "   ──────────────────────────── "
      )
      local overflow = #diagnostic_summary.messages - MAX_TOOLTIP_MESSAGES
      for j, msg in ipairs(diagnostic_summary.messages) do
        if j > MAX_TOOLTIP_MESSAGES then
          table.insert(tooltip_lines, "   +" .. overflow .. " more ")
          break
        end
        local sev_char = msg.severity == vim.diagnostic.severity.ERROR and "E"
          or "W"
        local text = string.format(
          "   %s  %s:%d  %s ",
          sev_char,
          msg.file,
          msg.lnum,
          msg.message
        )
        if vim.fn.strdisplaywidth(text) > TOOLTIP_MSG_MAX_W then
          text = text:sub(1, TOOLTIP_MSG_MAX_W - 1) .. "… "
        end
        table.insert(tooltip_lines, text)
      end
    end
  end

  local max_w = 0
  for _, line in ipairs(tooltip_lines) do
    max_w = math.max(max_w, vim.fn.strdisplaywidth(line))
  end

  local tooltip_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(tooltip_buf, 0, -1, false, tooltip_lines)

  local name_hl = is_entry_enabled and "DiagnosticOk" or "Comment"
  ui_utils.buf_hl(tooltip_buf, _state.tooltip_ns, name_hl, 0, 1, 4) -- ● / ○ = 3 bytes at col 1

  for i, line in ipairs(tooltip_lines) do
    if line:match("^   status:") then
      local prefix_len = #"   status: "
      ui_utils.buf_hl(
        tooltip_buf,
        _state.tooltip_ns,
        status_hl,
        i - 1,
        prefix_len,
        -1
      )
    elseif line:match("^   E  ") then
      ui_utils.buf_hl(
        tooltip_buf,
        _state.tooltip_ns,
        "DiagnosticError",
        i - 1,
        3,
        4
      )
    elseif line:match("^   W  ") then
      ui_utils.buf_hl(
        tooltip_buf,
        _state.tooltip_ns,
        "DiagnosticWarn",
        i - 1,
        3,
        4
      )
    end
  end

  local cursor = vim.api.nvim_win_get_cursor(_state.ui.win)
  local cursor_row = cursor[1] - 1
  local float_h = #tooltip_lines + 2
  local float_row = cursor_row - float_h
  if float_row < 0 then
    float_row = cursor_row + 1
  end

  local tooltip_win = vim.api.nvim_open_win(tooltip_buf, false, {
    relative = "win",
    win = _state.ui.win,
    row = float_row,
    col = entry.icon_byte,
    width = max_w,
    height = #tooltip_lines,
    style = "minimal",
    border = "single",
    focusable = false,
    zindex = 100,
    noautocmd = true,
  })

  local function close()
    if vim.api.nvim_win_is_valid(tooltip_win) then
      vim.api.nvim_win_close(tooltip_win, true)
    end
  end
  vim.defer_fn(close, 4000)
  vim.api.nvim_create_autocmd({ "CursorMoved", "WinClosed" }, {
    buffer = _state.ui.buf,
    once = true,
    callback = close,
  })
end

---@return nil
function M.do_toggle()
  local entry = current_entry()
  if not entry or not entry.meta then
    return
  end
  local category = cfg.service_categories[_state.ui.category_idx]
  local is_now_enabled = not state_mod.is_enabled(category, entry.name)

  if is_now_enabled and entry.meta.mason then
    local reg_ok, reg = pcall(require, "mason-registry")
    if reg_ok then
      local pkg_ok, pkg = pcall(reg.get_package, entry.meta.mason)
      if pkg_ok and pkg and not pkg:is_installed() then
        install_pkg(entry.meta.mason, function()
          state_mod.set_enabled(category, entry.name, true)
          category_handlers[category].apply_runtime({
            name = entry.name,
            meta = entry.meta,
            is_enabled = true,
          })
          _state.render()
        end)
        return
      end
    end
  end

  state_mod.set_enabled(category, entry.name, is_now_enabled)
  category_handlers[category].apply_runtime({
    name = entry.name,
    meta = entry.meta,
    is_enabled = is_now_enabled,
  })
  _state.render()
end

---@return nil
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
  install_pkg(entry.meta.mason, _state.render)
end

---@param dir integer -1 for up, 1 for down
---@return nil
function M.do_reorder(dir)
  local entry = current_entry()
  if not entry or not entry.ft then
    return
  end
  local category = cfg.service_categories[_state.ui.category_idx]

  local group
  for _, filetype_group in ipairs(data.build_ft_groups(category)) do
    if filetype_group.ft == entry.ft then
      group = filetype_group
      break
    end
  end
  if not group then
    return
  end

  local names = vim.deepcopy(group.names)
  local current_idx
  for i, n in ipairs(names) do
    if n == entry.name then
      current_idx = i
      break
    end
  end
  if not current_idx then
    return
  end

  local new_idx = current_idx + dir
  if new_idx < 1 or new_idx > #names then
    return
  end

  names[current_idx], names[new_idx] = names[new_idx], names[current_idx]

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
  local handler = category_handlers[category]
  if handler and handler.apply_order then
    handler.apply_order({ ft = entry.ft, enabled_names = enabled_names })
  end

  _state.render()

  for lnum, e in pairs(_state.ui.line_map) do
    if e.name == entry.name and e.ft == entry.ft then
      vim.api.nvim_win_set_cursor(_state.ui.win, { lnum, 0 })
      break
    end
  end
end

---@param idx integer
---@return nil
function M.switch_tab(idx)
  _state.ui.category_idx = idx
  _state.render()
  local first
  for lnum in pairs(_state.ui.line_map) do
    first = first and math.min(first, lnum) or lnum
  end
  if first and _state.ui.win and vim.api.nvim_win_is_valid(_state.ui.win) then
    vim.api.nvim_win_set_cursor(_state.ui.win, { first, 0 })
  end
end

return M
