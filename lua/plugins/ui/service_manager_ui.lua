local M = {}

local services = require("config.services")
local state_mod = require("utils.service_state")

-- ─── config ──────────────────────────────────────────────────────────────────

local cfg = {
  max_w = 120,
  min_w = 120,
  max_h = 40,
  min_h = 40,
  col_name = 28, -- name column width in flat view (LSP/DAP)
  col_ft = 18, -- filetype column width in flat view
  col_tool = 26, -- name column width in grouped view (linter/formatter)
  col_status = 22, -- status column width (both views)
  pad_flat = 2, -- left indent for LSP/DAP entries
  pad_tool = 4, -- left indent for linter/formatter entries
  cats = { "lsp", "dap", "linter", "formatter" },
  cat_label = {
    lsp = "LSP",
    dap = "DAP",
    linter = "Linter",
    formatter = "Formatter",
  },
}

local ELLIPSIS = "…" -- U+2026, 3 bytes, display width 1

local ui = {
  buf = nil,
  win = nil,
  cat_idx = 1,
  help_open = false,
  line_map = {},
  live_augroup = nil,
}

local ns = vim.api.nvim_create_namespace("ServiceManager")
local tooltip_ns = vim.api.nvim_create_namespace("ServiceManagerTooltip")

-- ─── layout helpers ───────────────────────────────────────────────────────────

local function trunc(s, max_w)
  if vim.fn.strdisplaywidth(s) <= max_w then
    return s
  end
  -- subtract actual display width of ELLIPSIS (1 normally, 2 with ambiwidth=double)
  local ew = vim.fn.strdisplaywidth(ELLIPSIS)
  return s:sub(1, max_w - ew) .. ELLIPSIS
end

local function rpad(s, w)
  local dw = vim.fn.strdisplaywidth(s)
  return dw < w and (s .. string.rep(" ", w - dw)) or s
end

-- Pads a line with trailing spaces to fill the full inner window width.
-- Ensures cursorline highlight extends to the right edge of the window.
local function fill_line(s, inner_w)
  local dw = vim.fn.strdisplaywidth(s)
  return dw < inner_w and (s .. string.rep(" ", inner_w - dw)) or s
end

-- Replacement for deprecated nvim_buf_add_highlight.
-- end_col = -1 resolves to the byte length of the target line.
local function buf_hl(buf, ns_id, hl_group, row, start_col, end_col)
  if end_col == -1 then
    local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ""
    end_col = #line
  end
  if end_col <= start_col then
    return
  end
  vim.api.nvim_buf_set_extmark(buf, ns_id, row, start_col, {
    end_col = end_col,
    hl_group = hl_group,
  })
end

-- Returns (text, hl_group). Text is never empty. hl reflects the worst state:
--   DiagnosticOk    = installed (and active for LSP)
--   DiagnosticWarn  = installed but idle (LSP), or no mason package
--   DiagnosticError = not installed
local function entry_status(cat, name, meta)
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
    local n = #vim.lsp.get_clients({ name = name })
    local is_enabled = vim.lsp.is_enabled(name)

    if not is_enabled then
      hl = "DiagnosticError"
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

-- ─── ft-grouped builder ───────────────────────────────────────────────────────

local function build_ft_groups(cat)
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

-- ─── window sizing ────────────────────────────────────────────────────────────

local function content_lines(cat)
  if cat == "lsp" or cat == "dap" then
    return vim.tbl_count(services[cat])
  end
  local h = 0
  for _, g in ipairs(build_ft_groups(cat)) do
    h = h + 1 + #g.names
  end
  return h
end

local function make_win_cfg()
  local W = math.min(
    vim.o.columns - 2,
    math.max(cfg.min_w, math.min(cfg.max_w, vim.o.columns - 4))
  )
  -- 1 empty + 1 tabline + 1 sep + 1 col-hdr + content
  local natural = 4 + content_lines(cfg.cats[ui.cat_idx])
  local H =
    math.min(vim.o.lines - 2, math.max(cfg.min_h, math.min(cfg.max_h, natural)))
  return {
    relative = "editor",
    width = W,
    height = H,
    row = math.floor((vim.o.lines - H) / 2),
    col = math.floor((vim.o.columns - W) / 2),
    style = "minimal",
    border = "rounded",
    title = " Service Manager ",
    title_pos = "center",
    noautocmd = true,
  }
end

-- ─── render ───────────────────────────────────────────────────────────────────

local function render()
  if not (ui.buf and vim.api.nvim_buf_is_valid(ui.buf)) then
    return
  end
  ui.help_open = false

  local cat = cfg.cats[ui.cat_idx]
  local W = vim.api.nvim_win_get_width(ui.win)
  local sep = string.rep("─", W - 4)

  -- ── tabline: uniform label format; highlight marks the active tab ──────────

  local tabline = "  "
  local tab_ranges = {}
  for i, c in ipairs(cfg.cats) do
    local lbl = "  " .. i .. " " .. cfg.cat_label[c] .. "  "
    local s = #tabline
    tabline = tabline .. lbl
    tab_ranges[i] = { s, #tabline }
  end

  local gh_hint = "press g? for help"
  local gh_pad = math.max(
    0,
    W - vim.fn.strdisplaywidth(tabline) - vim.fn.strdisplaywidth(gh_hint) - 2
  )
  local gh_byte = #tabline + gh_pad
  tabline = tabline .. string.rep(" ", gh_pad) .. gh_hint

  -- ── column header ─────────────────────────────────────────────────────────
  -- measure icon display width at runtime; ● is East Asian Ambiguous (1 or 2)
  local icon_disp_w = vim.fn.strdisplaywidth("●")

  local col_hdr
  if cat == "lsp" or cat == "dap" then
    col_hdr = string.rep(" ", cfg.pad_flat + icon_disp_w + 2)
      .. rpad("Service", cfg.col_name)
      .. "  "
      .. rpad("Filetypes", cfg.col_ft)
      .. "  "
      .. "Status"
  else
    col_hdr = string.rep(" ", cfg.pad_tool + icon_disp_w + 2)
      .. rpad("Service", cfg.col_tool)
      .. "  "
      .. rpad("Filetypes", cfg.col_ft)
      .. "  "
      .. "Status"
  end

  local lines = {
    fill_line("", W),
    fill_line(tabline, W),
    fill_line("  " .. sep, W),
    fill_line(col_hdr, W),
  }
  local header_lnums = {}
  ui.line_map = {}

  -- ── content ───────────────────────────────────────────────────────────────

  if cat == "lsp" or cat == "dap" then
    local flat = {}
    for name, meta in pairs(services[cat]) do
      table.insert(flat, { name = name, meta = meta })
    end
    table.sort(flat, function(a, b)
      return a.name < b.name
    end)

    for _, e in ipairs(flat) do
      local enabled = state_mod.is_enabled(cat, e.name)
      local icon = enabled and "●" or "○"
      local dname = trunc(e.name, cfg.col_name)
      local ft_str = table.concat(e.meta.ft or {}, " ")
      local dft = trunc(ft_str, cfg.col_ft)
      local st_text, st_hl = entry_status(cat, e.name, e.meta)

      local icon_gap =
        string.rep(" ", icon_disp_w - vim.fn.strdisplaywidth(icon) + 2)
      local prefix = string.rep(" ", cfg.pad_flat)
        .. icon
        .. icon_gap
        .. rpad(dname, cfg.col_name)
        .. "  "
        .. rpad(dft, cfg.col_ft)
        .. "  "
      table.insert(
        lines,
        fill_line(prefix .. trunc(st_text, cfg.col_status), W)
      )
      ui.line_map[#lines] = {
        name = e.name,
        meta = e.meta,
        icon_byte = cfg.pad_flat,
        status_byte = #prefix,
        status_hl = st_hl,
      }
    end
  else
    for _, grp in ipairs(build_ft_groups(cat)) do
      table.insert(lines, fill_line("  " .. grp.ft, W))
      header_lnums[#lines] = true

      for _, name in ipairs(grp.names) do
        local meta = services[cat][name]
        if meta then
          local enabled = state_mod.is_enabled(cat, name)
          local icon = enabled and "●" or "○"
          local dname = trunc(name, cfg.col_tool)
          local ft_str = table.concat(meta.ft or {}, " ")
          local dft = trunc(ft_str, cfg.col_ft)
          local st_text, st_hl = entry_status(cat, name, meta)

          local icon_gap =
            string.rep(" ", icon_disp_w - vim.fn.strdisplaywidth(icon) + 2)
          local prefix = string.rep(" ", cfg.pad_tool)
            .. icon
            .. icon_gap
            .. rpad(dname, cfg.col_tool)
            .. "  "
            .. rpad(dft, cfg.col_ft)
            .. "  "
          table.insert(
            lines,
            fill_line(prefix .. trunc(st_text, cfg.col_status), W)
          )
          ui.line_map[#lines] = {
            name = name,
            ft = grp.ft,
            meta = meta,
            icon_byte = cfg.pad_tool,
            status_byte = #prefix,
            status_hl = st_hl,
          }
        end
      end
    end
  end

  -- write buffer
  vim.bo[ui.buf].modifiable = true
  vim.api.nvim_buf_set_lines(ui.buf, 0, -1, false, lines)
  vim.bo[ui.buf].modifiable = false

  -- ── highlights ────────────────────────────────────────────────────────────

  vim.api.nvim_buf_clear_namespace(ui.buf, ns, 0, -1)

  -- tabs: active = DiagnosticVirtualTextInfo, inactive = TabLine
  for i, range in ipairs(tab_ranges) do
    local hl = (i == ui.cat_idx) and "DiagnosticVirtualTextInfo" or "TabLine"
    buf_hl(ui.buf, ns, hl, 1, range[1], range[2])
  end
  buf_hl(ui.buf, ns, "Comment", 1, gh_byte, gh_byte + #gh_hint)

  -- column header (0-indexed row 3)
  buf_hl(ui.buf, ns, "Comment", 3, 0, -1)

  -- icons + status
  for lnum, entry in pairs(ui.line_map) do
    local icon_hl = state_mod.is_enabled(cat, entry.name) and "DiagnosticOk"
      or "Comment"
    buf_hl(ui.buf, ns, icon_hl, lnum - 1, entry.icon_byte, entry.icon_byte + 3)
    buf_hl(ui.buf, ns, entry.status_hl, lnum - 1, entry.status_byte, -1)
  end

  -- ft group headers
  for lnum in pairs(header_lnums) do
    buf_hl(ui.buf, ns, "Title", lnum - 1, 0, -1)
  end

  -- ── resize ────────────────────────────────────────────────────────────────

  if ui.win and vim.api.nvim_win_is_valid(ui.win) then
    local wcfg = make_win_cfg()
    vim.api.nvim_win_set_config(ui.win, {
      relative = "editor",
      height = wcfg.height,
      row = wcfg.row,
      col = wcfg.col,
    })
  end

  -- ── clamp cursor to entry lines ───────────────────────────────────────────

  if ui.win and vim.api.nvim_win_is_valid(ui.win) then
    local cur = vim.api.nvim_win_get_cursor(ui.win)[1]
    local first_e, last_e
    for lnum in pairs(ui.line_map) do
      first_e = first_e and math.min(first_e, lnum) or lnum
      last_e = last_e and math.max(last_e, lnum) or lnum
    end
    if first_e then
      if cur < first_e then
        vim.api.nvim_win_set_cursor(ui.win, { first_e, 0 })
      elseif cur > last_e then
        vim.api.nvim_win_set_cursor(ui.win, { last_e, 0 })
      end
    end
  end
end

-- ─── help page ───────────────────────────────────────────────────────────────

local function render_help()
  if not (ui.buf and vim.api.nvim_buf_is_valid(ui.buf)) then
    return
  end

  local W = vim.api.nvim_win_get_width(ui.win)
  local sep = string.rep("─", W - 4)

  local lines = {}
  local section_lnums = {}

  local function sec(title)
    table.insert(lines, fill_line("", W))
    table.insert(lines, fill_line("  " .. title, W))
    section_lnums[#lines] = true
  end

  local function row(key, desc)
    table.insert(lines, fill_line(string.format("  %-18s %s", key, desc), W))
  end

  table.insert(lines, fill_line("", W))
  table.insert(lines, fill_line("  ? Help", W))
  table.insert(lines, fill_line("  " .. sep, W))

  sec("Navigation")
  row("1-4", "Switch tab  LSP / DAP / LINTER / FORMATTER")
  row("<Tab>", "Next tab")
  row("<S-Tab>", "Previous tab")

  sec("Actions")
  row("<Space> / <CR>", "Toggle enable / disable")
  row("i", "Install mason package")
  row("[ / ]", "Reorder up / down (LINTER / FORMATTER only)")
  row("K", "Show full details (all tabs)")

  sec("General")
  row("g?", "Toggle this help page")
  row("q / <Esc>", "Close Service Manager")

  vim.bo[ui.buf].modifiable = true
  vim.api.nvim_buf_set_lines(ui.buf, 0, -1, false, lines)
  vim.bo[ui.buf].modifiable = false

  vim.api.nvim_buf_clear_namespace(ui.buf, ns, 0, -1)

  for lnum in pairs(section_lnums) do
    buf_hl(ui.buf, ns, "Title", lnum - 1, 0, -1)
  end
end

local function toggle_help()
  ui.help_open = not ui.help_open
  if ui.help_open then
    render_help()
  else
    render()
  end
end

-- ─── live update ─────────────────────────────────────────────────────────────

-- Re-renders whenever LSP clients attach or detach while the window is open.
local function start_live_update()
  if ui.live_augroup then
    return
  end
  ui.live_augroup =
    vim.api.nvim_create_augroup("ServiceManagerLive", { clear = true })
  vim.api.nvim_create_autocmd({ "LspAttach", "LspDetach" }, {
    group = ui.live_augroup,
    callback = function()
      vim.schedule(function()
        if
          ui.win
          and vim.api.nvim_win_is_valid(ui.win)
          and not ui.help_open
        then
          render()
        end
      end)
    end,
  })
end

local function stop_live_update()
  if ui.live_augroup then
    pcall(vim.api.nvim_del_augroup_by_id, ui.live_augroup)
    ui.live_augroup = nil
  end
end

-- ─── actions ──────────────────────────────────────────────────────────────────

local function current_entry()
  if not ui.win then
    return nil
  end
  return ui.line_map[vim.api.nvim_win_get_cursor(ui.win)[1]]
end

local function show_tooltip(entry)
  local meta = entry.meta
  if not meta then
    return
  end
  local cat = cfg.cats[ui.cat_idx]

  -- mason install status
  local install_status = ""
  if meta.mason then
    local ok, reg = pcall(require, "mason-registry")
    if ok then
      local ok2, pkg = pcall(function()
        return reg.get_package(meta.mason)
      end)
      install_status = (ok2 and pkg and pkg:is_installed()) and " ✓" or " ✗"
    end
  end

  local enabled = state_mod.is_enabled(cat, entry.name)
  local icon = enabled and "●" or "○"
  local ft_str = table.concat(meta.ft or {}, "  ")
  local st_text, st_hl = entry_status(cat, entry.name, meta)

  local info = {}
  table.insert(info, " " .. icon .. "  " .. entry.name .. " ")
  if ft_str ~= "" then
    table.insert(info, "   ft:     " .. ft_str .. " ")
  end
  if meta.mason then
    table.insert(info, "   mason:  " .. meta.mason .. install_status .. " ")
  end
  table.insert(info, "   status: " .. st_text .. " ")
  if meta.note and meta.note ~= "" then
    table.insert(info, "   note:   " .. meta.note .. " ")
  end

  local max_w = 0
  for _, line in ipairs(info) do
    max_w = math.max(max_w, vim.fn.strdisplaywidth(line))
  end

  local tbuf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(tbuf, 0, -1, false, info)
  -- highlight name row icon, then status row
  local name_hl = enabled and "DiagnosticOk" or "Comment"
  buf_hl(tbuf, tooltip_ns, name_hl, 0, 1, 4) -- ● / ○ = 3 bytes starting at col 1
  for i, line in ipairs(info) do
    if line:match("^   status:") then
      local prefix_b = #"   status: "
      buf_hl(tbuf, tooltip_ns, st_hl, i - 1, prefix_b, -1)
    end
  end

  local cursor = vim.api.nvim_win_get_cursor(ui.win)
  local crow = cursor[1] - 1 -- 0-indexed cursor row in the window
  local float_h = #info + 2 -- +2 for border
  -- show above cursor; fall back to below if not enough room
  local float_row = crow - float_h
  if float_row < 0 then
    float_row = crow + 1
  end

  local twin = vim.api.nvim_open_win(tbuf, false, {
    relative = "win",
    win = ui.win,
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
    if vim.api.nvim_win_is_valid(twin) then
      vim.api.nvim_win_close(twin, true)
    end
  end
  vim.defer_fn(close, 4000)
  vim.api.nvim_create_autocmd({ "CursorMoved", "WinClosed" }, {
    buffer = ui.buf,
    once = true,
    callback = close,
  })
end

local function install_pkg(pkg_name, on_done)
  if not pkg_name then
    return
  end
  local ok, reg = pcall(require, "mason-registry")

  if reg.is_installed(pkg_name) then
    vim.notify(pkg_name .. " is already installed", vim.log.levels.INFO)
    if on_done then
      on_done()
    end
    return
  else
    local ok, pkg = pcall(reg.get_package, pkg_name)
    if ok and pkg then
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
      return
    end
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
      for _, client in ipairs(vim.lsp.get_clients({ name = name })) do
        vim.lsp.stop_client(client.id, true)
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

local function do_toggle()
  local entry = current_entry()
  if not entry then
    return
  end
  local cat = cfg.cats[ui.cat_idx]
  local meta = entry.meta
  if not meta then
    return
  end
  local new_state = not state_mod.is_enabled(cat, entry.name)

  if new_state and meta.mason then
    local ok, reg = pcall(require, "mason-registry")
    if ok then
      local ok2, pkg = pcall(function()
        return reg.get_package(meta.mason)
      end)
      if ok2 and pkg and not pkg:is_installed() then
        install_pkg(meta.mason, function()
          state_mod.set_enabled(cat, entry.name, true)
          apply_runtime(cat, entry.name, meta, true)
          render()
        end)
        return
      end
    end
  end

  state_mod.set_enabled(cat, entry.name, new_state)
  apply_runtime(cat, entry.name, meta, new_state)
  render()
end

local function do_install()
  local entry = current_entry()
  if not entry then
    return
  end
  local cat = cfg.cats[ui.cat_idx]
  local meta = entry.meta
  if not meta then
    return
  end
  if not meta.mason then
    vim.notify(
      "No mason package for "
        .. entry.name
        .. (meta.note and (" — " .. meta.note) or ""),
      vim.log.levels.WARN
    )
    return
  end
  install_pkg(meta.mason, render)
end

local function do_reorder(dir)
  local entry = current_entry()
  if not entry or not entry.ft then
    return
  end
  local cat = cfg.cats[ui.cat_idx]

  local group
  for _, g in ipairs(build_ft_groups(cat)) do
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
  state_mod.set_order(cat, entry.ft, names)

  local enabled_names = vim.tbl_filter(function(n)
    return state_mod.is_enabled(cat, n)
  end, names)
  if cat == "formatter" then
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

  render()

  for lnum, e in pairs(ui.line_map) do
    if e.name == entry.name and e.ft == entry.ft then
      vim.api.nvim_win_set_cursor(ui.win, { lnum, 0 })
      break
    end
  end
end

local function switch_tab(idx)
  ui.cat_idx = idx
  render()
  local first
  for lnum in pairs(ui.line_map) do
    first = first and math.min(first, lnum) or lnum
  end
  if first and ui.win and vim.api.nvim_win_is_valid(ui.win) then
    vim.api.nvim_win_set_cursor(ui.win, { first, 0 })
  end
end

-- ─── keymaps ──────────────────────────────────────────────────────────────────

local function set_keymaps()
  local o = { buffer = ui.buf, nowait = true, silent = true }
  local function map(k, fn)
    vim.keymap.set("n", k, fn, o)
  end

  map("q", M.close)
  map("<Esc>", M.close)
  map("g?", toggle_help)
  map("<Space>", do_toggle)
  map("i", do_install)
  map("<Tab>", function()
    switch_tab((ui.cat_idx % #cfg.cats) + 1)
  end)
  map("<S-Tab>", function()
    switch_tab(((ui.cat_idx - 2) % #cfg.cats) + 1)
  end)
  map("[", function()
    do_reorder(-1)
  end)
  map("]", function()
    do_reorder(1)
  end)
  map("K", function()
    local entry = current_entry()
    if entry then
      show_tooltip(entry)
    end
  end)

  for i = 1, #cfg.cats do
    map(tostring(i), function()
      switch_tab(i)
    end)
  end
end

-- ─── open / close ─────────────────────────────────────────────────────────────

function M.open()
  if ui.win and vim.api.nvim_win_is_valid(ui.win) then
    vim.api.nvim_set_current_win(ui.win)
    return
  end

  ui.buf = vim.api.nvim_create_buf(false, true)
  vim.bo[ui.buf].filetype = "ServiceManager"
  vim.bo[ui.buf].bufhidden = "wipe"

  ui.win = vim.api.nvim_open_win(ui.buf, true, make_win_cfg())
  vim.wo[ui.win].cursorline = true
  vim.wo[ui.win].wrap = false
  vim.wo[ui.win].number = false
  vim.wo[ui.win].relativenumber = false

  set_keymaps()
  start_live_update()

  vim.api.nvim_create_autocmd("WinClosed", {
    buffer = ui.buf,
    once = true,
    callback = function()
      stop_live_update()
      ui.win = nil
      ui.buf = nil
    end,
  })

  render()

  local first
  for lnum in pairs(ui.line_map) do
    first = first and math.min(first, lnum) or lnum
  end
  if first then
    vim.api.nvim_win_set_cursor(ui.win, { first, 0 })
  end
end

function M.close()
  if ui.win and vim.api.nvim_win_is_valid(ui.win) then
    vim.api.nvim_win_close(ui.win, true)
  end
  ui.win = nil
  ui.buf = nil
end

return M
