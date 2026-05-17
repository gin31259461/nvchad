local M = {}

local cfg = require("plugins.ui.service_manager_config")
local data = require("plugins.ui.service_manager_data")
local services = require("config.services")
local state_mod = require("utils.service_state")
local ui_utils = require("utils.ui")

local _state = { ui = nil, ns = nil }

function M.init(ui, ns)
  _state.ui = ui
  _state.ns = ns
end

function M.make_win_cfg()
  local win_width = math.min(
    vim.o.columns - 2,
    math.max(cfg.min_w, math.min(cfg.max_w, vim.o.columns - 4))
  )
  local natural = 4
    + data.content_lines(cfg.service_categories[_state.ui.cat_idx])
  local win_height =
    math.min(vim.o.lines - 2, math.max(cfg.min_h, math.min(cfg.max_h, natural)))
  return {
    relative = "editor",
    width = win_width,
    height = win_height,
    row = math.floor((vim.o.lines - win_height) / 2),
    col = math.floor((vim.o.columns - win_width) / 2),
    style = "minimal",
    border = "rounded",
    title = " Service Manager ",
    title_pos = "center",
    noautocmd = true,
  }
end

local function build_tabline(win_width)
  local tabline = "  "
  local tab_ranges = {}
  for i, c in ipairs(cfg.service_categories) do
    local lbl = "  " .. i .. " " .. cfg.cat_label[c] .. "  "
    local start_byte = #tabline
    tabline = tabline .. lbl
    tab_ranges[i] = { start_byte, #tabline }
  end

  local hint = "press g? for help"
  local hint_pad = math.max(
    0,
    win_width
      - vim.fn.strdisplaywidth(tabline)
      - vim.fn.strdisplaywidth(hint)
      - 2
  )
  local hint_byte = #tabline + hint_pad
  tabline = tabline .. string.rep(" ", hint_pad) .. hint

  return tabline, tab_ranges, hint_byte, hint
end

local function build_col_header(cat, icon_disp_w)
  if cat == "lsp" or cat == "dap" then
    return string.rep(" ", cfg.pad_flat + icon_disp_w + 2)
      .. ui_utils.rpad("Service", cfg.col_name)
      .. "  "
      .. ui_utils.rpad("Filetypes", cfg.col_ft)
      .. "  "
      .. "Status"
  end
  return string.rep(" ", cfg.pad_tool + icon_disp_w + 2)
    .. ui_utils.rpad("Service", cfg.col_tool)
    .. "  "
    .. ui_utils.rpad("Filetypes", cfg.col_ft)
    .. "  "
    .. "Status"
end

function M.render()
  if not (_state.ui.buf and vim.api.nvim_buf_is_valid(_state.ui.buf)) then
    return
  end
  _state.ui.help_open = false

  local cat = cfg.service_categories[_state.ui.cat_idx]
  -- measure icon display width at runtime; ● is East Asian Ambiguous (1 or 2)
  local icon_disp_w = vim.fn.strdisplaywidth("●")
  local win_width = vim.api.nvim_win_get_width(_state.ui.win)
  local sep = string.rep("─", win_width - 4)

  local tabline, tab_ranges, hint_byte, hint = build_tabline(win_width)
  local col_hdr = build_col_header(cat, icon_disp_w)

  local lines = {
    ui_utils.fill_line("", win_width),
    ui_utils.fill_line(tabline, win_width),
    ui_utils.fill_line("  " .. sep, win_width),
    ui_utils.fill_line(col_hdr, win_width),
  }
  local header_lnums = {}
  _state.ui.line_map = {}

  if cat == "lsp" or cat == "dap" then
    local flat = {}
    for name, meta in pairs(services[cat]) do
      table.insert(flat, { name = name, meta = meta })
    end
    table.sort(flat, function(a, b)
      return a.name < b.name
    end)

    for _, svc in ipairs(flat) do
      local is_enabled = state_mod.is_enabled(cat, svc.name)
      local icon = is_enabled and "●" or "○"
      local display_name = ui_utils.trunc(svc.name, cfg.col_name)
      local ft_str = table.concat(svc.meta.ft or {}, ", ")
      local display_ft = ui_utils.trunc(ft_str, cfg.col_ft)
      local status_text, status_hl = data.entry_status(cat, svc.name, svc.meta)

      local icon_gap =
        string.rep(" ", icon_disp_w - vim.fn.strdisplaywidth(icon) + 2)
      local prefix = string.rep(" ", cfg.pad_flat)
        .. icon
        .. icon_gap
        .. ui_utils.rpad(display_name, cfg.col_name)
        .. "  "
        .. ui_utils.rpad(display_ft, cfg.col_ft)
        .. "  "
      table.insert(
        lines,
        ui_utils.fill_line(
          prefix .. ui_utils.trunc(status_text, cfg.col_status),
          win_width
        )
      )
      _state.ui.line_map[#lines] = {
        name = svc.name,
        meta = svc.meta,
        icon_byte = cfg.pad_flat,
        status_byte = #prefix,
        status_hl = status_hl,
      }
    end
  else
    for _, grp in ipairs(data.build_ft_groups(cat)) do
      table.insert(lines, ui_utils.fill_line("  " .. grp.ft, win_width))
      header_lnums[#lines] = true

      for _, name in ipairs(grp.names) do
        local meta = services[cat][name]
        if meta then
          local is_enabled = state_mod.is_enabled(cat, name)
          local icon = is_enabled and "●" or "○"
          local display_name = ui_utils.trunc(name, cfg.col_tool)
          local ft_str = table.concat(meta.ft or {}, " ")
          local display_ft = ui_utils.trunc(ft_str, cfg.col_ft)
          local status_text, status_hl = data.entry_status(cat, name, meta)

          local icon_gap =
            string.rep(" ", icon_disp_w - vim.fn.strdisplaywidth(icon) + 2)
          local prefix = string.rep(" ", cfg.pad_tool)
            .. icon
            .. icon_gap
            .. ui_utils.rpad(display_name, cfg.col_tool)
            .. "  "
            .. ui_utils.rpad(display_ft, cfg.col_ft)
            .. "  "
          table.insert(
            lines,
            ui_utils.fill_line(
              prefix .. ui_utils.trunc(status_text, cfg.col_status),
              win_width
            )
          )
          _state.ui.line_map[#lines] = {
            name = name,
            ft = grp.ft,
            meta = meta,
            icon_byte = cfg.pad_tool,
            status_byte = #prefix,
            status_hl = status_hl,
          }
        end
      end
    end
  end

  vim.bo[_state.ui.buf].modifiable = true
  vim.api.nvim_buf_set_lines(_state.ui.buf, 0, -1, false, lines)
  vim.bo[_state.ui.buf].modifiable = false

  vim.api.nvim_buf_clear_namespace(_state.ui.buf, _state.ns, 0, -1)

  for i, range in ipairs(tab_ranges) do
    local tab_highlight = (i == _state.ui.cat_idx)
        and "DiagnosticVirtualTextInfo"
      or "TabLine"
    ui_utils.buf_hl(
      _state.ui.buf,
      _state.ns,
      tab_highlight,
      1,
      range[1],
      range[2]
    )
  end
  ui_utils.buf_hl(
    _state.ui.buf,
    _state.ns,
    "Comment",
    1,
    hint_byte,
    hint_byte + #hint
  )
  ui_utils.buf_hl(_state.ui.buf, _state.ns, "Comment", 3, 0, -1)

  for lnum, entry in pairs(_state.ui.line_map) do
    local icon_hl = state_mod.is_enabled(cat, entry.name) and "DiagnosticOk"
      or "Comment"
    ui_utils.buf_hl(
      _state.ui.buf,
      _state.ns,
      icon_hl,
      lnum - 1,
      entry.icon_byte,
      entry.icon_byte + 3
    )
    ui_utils.buf_hl(
      _state.ui.buf,
      _state.ns,
      entry.status_hl,
      lnum - 1,
      entry.status_byte,
      -1
    )
  end

  for lnum in pairs(header_lnums) do
    ui_utils.buf_hl(_state.ui.buf, _state.ns, "Title", lnum - 1, 0, -1)
  end

  if _state.ui.win and vim.api.nvim_win_is_valid(_state.ui.win) then
    local wcfg = M.make_win_cfg()
    vim.api.nvim_win_set_config(_state.ui.win, {
      relative = "editor",
      height = wcfg.height,
      row = wcfg.row,
      col = wcfg.col,
    })

    local cur = vim.api.nvim_win_get_cursor(_state.ui.win)[1]
    local first_entry_lnum, last_entry_lnum
    for lnum in pairs(_state.ui.line_map) do
      first_entry_lnum = first_entry_lnum and math.min(first_entry_lnum, lnum)
        or lnum
      last_entry_lnum = last_entry_lnum and math.max(last_entry_lnum, lnum)
        or lnum
    end
    if first_entry_lnum then
      if cur < first_entry_lnum then
        vim.api.nvim_win_set_cursor(_state.ui.win, { first_entry_lnum, 0 })
      elseif cur > last_entry_lnum then
        vim.api.nvim_win_set_cursor(_state.ui.win, { last_entry_lnum, 0 })
      end
    end
  end
end

function M.render_help()
  if not (_state.ui.buf and vim.api.nvim_buf_is_valid(_state.ui.buf)) then
    return
  end

  local win_width = vim.api.nvim_win_get_width(_state.ui.win)
  local sep = string.rep("─", win_width - 4)

  local lines = {}
  local section_lnums = {}

  local function render_section(title)
    table.insert(lines, ui_utils.fill_line("", win_width))
    table.insert(lines, ui_utils.fill_line("  " .. title, win_width))
    section_lnums[#lines] = true
  end

  local function row(key, desc)
    table.insert(
      lines,
      ui_utils.fill_line(string.format("  %-18s %s", key, desc), win_width)
    )
  end

  table.insert(lines, ui_utils.fill_line("", win_width))
  table.insert(lines, ui_utils.fill_line("  ? Help", win_width))
  table.insert(lines, ui_utils.fill_line("  " .. sep, win_width))

  render_section("Navigation")
  row("1-4", "Switch tab  LSP / DAP / LINTER / FORMATTER")
  row("<Tab>", "Next tab")
  row("<S-Tab>", "Previous tab")

  render_section("Actions")
  row("<Space> / <CR>", "Toggle enable / disable")
  row("i", "Install mason package")
  row("[ / ]", "Reorder up / down (LINTER / FORMATTER only)")
  row("K", "Show full details (all tabs)")

  render_section("General")
  row("g?", "Toggle this help page")
  row("q / <Esc>", "Close Service Manager")

  vim.bo[_state.ui.buf].modifiable = true
  vim.api.nvim_buf_set_lines(_state.ui.buf, 0, -1, false, lines)
  vim.bo[_state.ui.buf].modifiable = false

  vim.api.nvim_buf_clear_namespace(_state.ui.buf, _state.ns, 0, -1)

  for lnum in pairs(section_lnums) do
    ui_utils.buf_hl(_state.ui.buf, _state.ns, "Title", lnum - 1, 0, -1)
  end
end

function M.toggle_help()
  _state.ui.help_open = not _state.ui.help_open
  if _state.ui.help_open then
    M.render_help()
  else
    M.render()
  end
end

function M.start_live_update()
  if _state.ui.live_augroup then
    return
  end
  _state.ui.live_augroup =
    vim.api.nvim_create_augroup("ServiceManagerLive", { clear = true })
  vim.api.nvim_create_autocmd({ "LspAttach", "LspDetach" }, {
    group = _state.ui.live_augroup,
    callback = function()
      vim.schedule(function()
        if
          _state.ui.win
          and vim.api.nvim_win_is_valid(_state.ui.win)
          and not _state.ui.help_open
        then
          M.render()
        end
      end)
    end,
  })
end

function M.stop_live_update()
  if _state.ui.live_augroup then
    pcall(vim.api.nvim_del_augroup_by_id, _state.ui.live_augroup)
    _state.ui.live_augroup = nil
  end
end

return M
