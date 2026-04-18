-- Two-panel picker UI (Telescope-style)
-- Left : search input (top) + item list (below)
-- Right: output / preview panel
--
-- Usage:
--   require("utils.dotnet-ui").open(commands, { title = "..." })
--
-- Command spec:
--   { name, icon, icon_hl?, desc?, action: fun(ctx) }
--
-- ctx passed to action:
--   ctx.write(lines)   – append string or string[] to output
--   ctx.clear()        – clear output
--   ctx.append(line)   – append a single line
--   ctx.select(items, opts) – push a sub-selection list onto the left panel
--     opts: { title?, on_select: fun(item, ctx), on_cancel?: fun() }

local M   = {}
local api = vim.api

-- ── active UI state ───────────────────────────────────────────────────────────
local S = {}

local function is_open()
  return S.ns ~= nil
end

-- ── output highlight patterns ─────────────────────────────────────────────────
local OUT_HL_PATTERNS = {
  { pat = "^%$ ",              line_hl = "Comment" },
  { pat = "✓",                 line_hl = "DiagnosticOk" },
  { pat = "✗",                 line_hl = "DiagnosticError" },
  { pat = "Build succeeded",   line_hl = "DiagnosticOk" },
  { pat = "Build FAILED",      line_hl = "DiagnosticError" },
  { pat = "[Ww]arning%s",      line_hl = "DiagnosticWarn" },
  { pat = "[Ee]rror%s",        line_hl = "DiagnosticError" },
  { pat = "Restored%s",        line_hl = "DiagnosticOk" },
  { pat = "Passed!",           line_hl = "DiagnosticOk" },
  { pat = "Failed!",           line_hl = "DiagnosticError" },
}

-- ── output highlight helper ───────────────────────────────────────────────────

---Apply line-level highlights to output lines matching known patterns.
---@param start_line integer  0-based first line
---@param end_line   integer  0-based one-past-last line
local function highlight_output(start_line, end_line)
  if not (S.output_buf and api.nvim_buf_is_valid(S.output_buf)) then return end
  if not S.out_ns then return end

  local lines = api.nvim_buf_get_lines(S.output_buf, start_line, end_line, false)
  for i, line in ipairs(lines) do
    local row = start_line + i - 1
    for _, rule in ipairs(OUT_HL_PATTERNS) do
      if line:find(rule.pat) then
        api.nvim_buf_set_extmark(S.output_buf, S.out_ns, row, 0, {
          line_hl_group = rule.line_hl,
        })
        break
      end
    end
  end
end

-- ── output helpers ────────────────────────────────────────────────────────────

local function out_write(lines)
  if not (S.output_buf and api.nvim_buf_is_valid(S.output_buf)) then return end
  if type(lines) == "string" then lines = vim.split(lines, "\n") end

  -- jobstart sends a trailing "" as a chunk-end marker; strip it
  local to_write = {}
  for i, l in ipairs(lines) do
    if i < #lines or l ~= "" then
      table.insert(to_write, l)
    end
  end
  if #to_write == 0 then return end

  vim.bo[S.output_buf].modifiable = true
  local n     = api.nvim_buf_line_count(S.output_buf)
  -- When the buffer holds only the initial empty line, overwrite it rather
  -- than appending after it (avoids a leading blank on every fresh write).
  local start = n
  if n == 1 and api.nvim_buf_get_lines(S.output_buf, 0, 1, false)[1] == "" then
    start = 0
  end
  api.nvim_buf_set_lines(S.output_buf, start, -1, false, to_write)
  vim.bo[S.output_buf].modifiable = false

  highlight_output(start, start + #to_write)

  if S.output_win and api.nvim_win_is_valid(S.output_win) then
    local new_n = api.nvim_buf_line_count(S.output_buf)
    pcall(api.nvim_win_set_cursor, S.output_win, { new_n, 0 })
  end
end

local function out_clear()
  if not (S.output_buf and api.nvim_buf_is_valid(S.output_buf)) then return end
  vim.bo[S.output_buf].modifiable = true
  api.nvim_buf_set_lines(S.output_buf, 0, -1, false, {})
  vim.bo[S.output_buf].modifiable = false
  if S.out_ns then
    api.nvim_buf_clear_namespace(S.output_buf, S.out_ns, 0, -1)
  end
end

-- ── close ─────────────────────────────────────────────────────────────────────

local function do_close()
  if not is_open() then return end
  for _, win in ipairs { S.input_win, S.list_win, S.output_win } do
    pcall(api.nvim_win_close, win, true)
  end
  for _, buf in ipairs { S.input_buf, S.list_buf, S.output_buf } do
    pcall(api.nvim_buf_delete, buf, { force = true })
  end
  S = {}
  vim.cmd("stopinsert")
end

-- ── list rendering ────────────────────────────────────────────────────────────

local function current_items()
  return S.sub and S.sub.items or S.filtered
end

local function current_selected()
  return S.sub and S.sub.selected or S.selected
end

local function render_list()
  if not (S.list_buf and api.nvim_buf_is_valid(S.list_buf)) then return end

  local items    = current_items()
  local sel      = current_selected()

  api.nvim_buf_clear_namespace(S.list_buf, S.ns, 0, -1)
  vim.bo[S.list_buf].modifiable = true

  local lines = {}
  for _, item in ipairs(items) do
    if type(item) == "string" then
      table.insert(lines, "  " .. item)
    else
      -- table item: must have .icon and .name
      table.insert(lines, "  " .. item.icon .. "  " .. item.name)
    end
  end
  -- pad to fill the window height so highlights don't stop short
  while #lines < S.list_h do
    table.insert(lines, "")
  end

  api.nvim_buf_set_lines(S.list_buf, 0, -1, false, lines)

  for i, item in ipairs(items) do
    local row    = i - 1
    local is_sel = (i == sel)

    if is_sel then
      api.nvim_buf_set_extmark(S.list_buf, S.ns, row, 0, {
        line_hl_group = "Visual",
      })
    end

    if type(item) ~= "string" then
      local icon_hl = item.icon_hl or "String"
      local icon_start = 2
      local icon_end   = icon_start + #item.icon
      api.nvim_buf_set_extmark(S.list_buf, S.ns, row, icon_start, {
        end_col  = icon_end,
        hl_group = icon_hl,
      })
      local name_hl = is_sel and "CursorLineNr" or "Normal"
      api.nvim_buf_set_extmark(S.list_buf, S.ns, row, icon_end + 2, {
        end_col  = #lines[i],
        hl_group = name_hl,
      })
    else
      local hl = is_sel and "CursorLineNr" or "Normal"
      api.nvim_buf_set_extmark(S.list_buf, S.ns, row, 2, {
        end_col  = #lines[i],
        hl_group = hl,
      })
    end
  end

  vim.bo[S.list_buf].modifiable = false
end

-- ── filter ────────────────────────────────────────────────────────────────────

local function filter_commands(query)
  if not query or query == "" then
    S.filtered = vim.deepcopy(S.commands)
  else
    local q    = query:lower()
    S.filtered = {}
    for _, item in ipairs(S.commands) do
      if item.name:lower():find(q, 1, true)
        or (item.desc and item.desc:lower():find(q, 1, true))
      then
        table.insert(S.filtered, item)
      end
    end
  end
  S.selected = math.min(S.selected, math.max(1, #S.filtered))
end

-- ── ctx factory ───────────────────────────────────────────────────────────────

local function make_ctx()
  return {
    write  = out_write,
    clear  = out_clear,
    append = function(line) out_write({ line }) end,

    ---Push a temporary sub-selection list into the left panel.
    ---@param items  string[]|table[]
    ---@param opts   {title?: string, on_select: fun(item: any, ctx: table), on_cancel?: fun()}
    select = function(items, opts)
      S.sub = {
        items     = items,
        selected  = 1,
        on_select = opts.on_select,
        on_cancel = opts.on_cancel,
      }
      -- update left panel title
      pcall(api.nvim_win_set_config, S.list_win, {
        title     = " " .. (opts.title or "Select") .. " ",
        title_pos = "center",
      })
      render_list()
      -- keep cursor in input
      if S.input_win and api.nvim_win_is_valid(S.input_win) then
        api.nvim_set_current_win(S.input_win)
        vim.cmd("startinsert")
      end
    end,
  }
end

-- ── execute selected ──────────────────────────────────────────────────────────

local function run_selected()
  local items   = current_items()
  local sel     = current_selected()
  if #items == 0 then return end
  local item = items[sel]
  if not item then return end

  if S.sub then
    local on_select = S.sub.on_select
    S.sub = nil
    -- restore list panel title
    pcall(api.nvim_win_set_config, S.list_win, {
      title     = " " .. S.list_title .. " ",
      title_pos = "center",
    })
    filter_commands(S.last_query or "")
    render_list()
    if on_select then
      on_select(item, make_ctx())
    end
  else
    if item.action then
      item.action(make_ctx())
    end
  end
end

-- ── navigation ────────────────────────────────────────────────────────────────

local function move(delta)
  local n = #current_items()
  if n == 0 then return end
  if S.sub then
    S.sub.selected = math.max(1, math.min(n, S.sub.selected + delta))
  else
    S.selected = math.max(1, math.min(n, S.selected + delta))
  end
  render_list()
end

local function handle_esc()
  if S.sub then
    local on_cancel = S.sub.on_cancel
    S.sub = nil
    pcall(api.nvim_win_set_config, S.list_win, {
      title     = " " .. S.list_title .. " ",
      title_pos = "center",
    })
    filter_commands(S.last_query or "")
    render_list()
    if on_cancel then on_cancel() end
  else
    do_close()
  end
end

-- ── keymaps ───────────────────────────────────────────────────────────────────

local function setup_keymaps()
  local function km(mode, lhs, fn, buf)
    vim.keymap.set(mode, lhs, fn, { buffer = buf, nowait = true })
  end

  for _, buf in ipairs { S.input_buf, S.list_buf, S.output_buf } do
    km({ "n", "i" }, "<Esc>", handle_esc, buf)
    km("n", "q", handle_esc, buf)
  end

  -- navigate from the input (insert mode)
  km("i", "<C-j>",   function() move(1) end,  S.input_buf)
  km("i", "<C-k>",   function() move(-1) end, S.input_buf)
  km("i", "<Down>",  function() move(1) end,  S.input_buf)
  km("i", "<Up>",    function() move(-1) end, S.input_buf)
  km("i", "<CR>",    run_selected,            S.input_buf)

  -- navigate from the input (normal mode)
  km("n", "j",    function() move(1) end,  S.input_buf)
  km("n", "k",    function() move(-1) end, S.input_buf)
  km("n", "<CR>", run_selected,            S.input_buf)

  -- navigate from the list (normal mode)
  km("n", "j",    function() move(1) end,  S.list_buf)
  km("n", "k",    function() move(-1) end, S.list_buf)
  km("n", "<CR>", run_selected,            S.list_buf)

  -- Tab: move focus to output panel
  km({ "n", "i" }, "<Tab>", function()
    if S.output_win and api.nvim_win_is_valid(S.output_win) then
      vim.cmd("stopinsert")
      api.nvim_set_current_win(S.output_win)
    end
  end, S.input_buf)

  -- Tab in output: return focus to input
  km("n", "<Tab>", function()
    if S.input_win and api.nvim_win_is_valid(S.input_win) then
      api.nvim_set_current_win(S.input_win)
      vim.cmd("startinsert")
    end
  end, S.output_buf)
end

-- ── autocmds ─────────────────────────────────────────────────────────────────

local function setup_autocmds()
  local aug      = api.nvim_create_augroup("DotnetUI", { clear = true })
  local promptw  = api.nvim_strwidth(S.prompt)

  api.nvim_create_autocmd("TextChangedI", {
    group  = aug,
    buffer = S.input_buf,
    callback = function()
      local line  = api.nvim_get_current_line()
      local query = line:sub(promptw + 1)
      S.last_query = query
      if not S.sub then
        S.selected = 1
        filter_commands(query)
        render_list()
      end
    end,
  })

  -- When any panel window is closed externally, close the whole UI
  api.nvim_create_autocmd("WinClosed", {
    group = aug,
    callback = function(ev)
      local closed = tonumber(ev.match)
      if S.input_win and (
        closed == S.input_win
        or closed == S.list_win
        or closed == S.output_win
      ) then
        vim.schedule(do_close)
      end
    end,
  })
end

-- ── open ─────────────────────────────────────────────────────────────────────

---@class DotnetUICommand
---@field name     string
---@field icon     string
---@field icon_hl? string   highlight group for the icon (default "String")
---@field desc?    string   used for fuzzy filtering
---@field action   fun(ctx: DotnetUICtx)

---@class DotnetUICtx
---@field write   fun(lines: string[]|string)
---@field clear   fun()
---@field append  fun(line: string)
---@field select  fun(items: any[], opts: {title?: string, on_select: fun(item: any, ctx: DotnetUICtx), on_cancel?: fun()})

---Open the two-panel Dotnet Manager UI.
---@param commands DotnetUICommand[]
---@param opts?    {title?: string}
M.open = function(commands, opts)
  if is_open() then do_close() end
  opts = opts or {}

  -- ── layout math ──────────────────────────────────────────────────────────
  local total_w   = math.floor(vim.o.columns * 0.86)
  local total_h   = math.floor(vim.o.lines   * 0.78)
  local list_w    = math.floor(total_w * 0.38)
  local output_w  = total_w - list_w - 4       -- 4 = left+right borders of both wins
  local col_start = math.floor((vim.o.columns - total_w) / 2)
  local row_start = math.floor((vim.o.lines   - total_h) / 2)
  local list_h    = total_h - 3                -- 3 = input win height including borders
  local prompt    = "   "
  local title     = opts.title or "Commands"

  S = {
    commands   = commands,
    filtered   = vim.deepcopy(commands),
    selected   = 1,
    sub        = nil,
    last_query = "",
    prompt     = prompt,
    list_h     = list_h,
    list_title = title,
    ns         = api.nvim_create_namespace("DotnetUI"),
    out_ns     = api.nvim_create_namespace("DotnetUIOutput"),
  }

  -- ── buffers ───────────────────────────────────────────────────────────────
  S.input_buf  = api.nvim_create_buf(false, true)
  S.list_buf   = api.nvim_create_buf(false, true)
  S.output_buf = api.nvim_create_buf(false, true)

  -- ── windows ───────────────────────────────────────────────────────────────
  -- Input (top-left)
  S.input_win = api.nvim_open_win(S.input_buf, true, {
    relative  = "editor",
    row       = row_start,
    col       = col_start,
    width     = list_w,
    height    = 1,
    border    = "single",
    style     = "minimal",
    title     = " " .. title .. " ",
    title_pos = "center",
    zindex    = 50,
  })

  -- List (bottom-left, directly below input)
  S.list_win = api.nvim_open_win(S.list_buf, false, {
    relative  = "editor",
    row       = row_start + 3,    -- input height (1) + 2 borders
    col       = col_start,
    width     = list_w,
    height    = list_h,
    border    = "single",
    style     = "minimal",
    zindex    = 50,
  })

  -- Output (right side, full height, adjacent to list)
  S.output_win = api.nvim_open_win(S.output_buf, false, {
    relative  = "editor",
    row       = row_start,
    col       = col_start + list_w + 2,   -- right after left panel border
    width     = output_w,
    height    = total_h,
    border    = "single",
    style     = "minimal",
    title     = " Output ",
    title_pos = "center",
    zindex    = 50,
  })

  -- ── window options ────────────────────────────────────────────────────────
  local use_dark = vim.fn.hlID("ExBlack2Bg") ~= 0
  local win_hl   = use_dark
    and "Normal:ExBlack2Bg,FloatBorder:ExBlack2Border"
    or  "Normal:NormalFloat,FloatBorder:FloatBorder"

  for _, win in ipairs { S.input_win, S.list_win, S.output_win } do
    vim.wo[win].winhl         = win_hl
    vim.wo[win].wrap          = false
    vim.wo[win].number        = false
    vim.wo[win].relativenumber = false
    vim.wo[win].signcolumn    = "no"
    vim.wo[win].cursorline    = false
  end
  vim.wo[S.output_win].wrap = true

  -- ── buffer options ────────────────────────────────────────────────────────
  vim.bo[S.output_buf].modifiable = false
  vim.bo[S.output_buf].buftype    = "nofile"
  vim.bo[S.list_buf].buftype      = "nofile"

  vim.bo[S.input_buf].buftype = "prompt"
  vim.fn.prompt_setprompt(S.input_buf, prompt)
  vim.cmd("startinsert")

  -- ── initial render ────────────────────────────────────────────────────────
  render_list()
  setup_keymaps()
  setup_autocmds()
end

return M
