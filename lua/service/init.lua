local M = {}

local cfg = require("service.config")
local renderer = require("service.renderer")
local actions = require("service.actions")

local ui = {
  buf = nil,
  win = nil,
  category_idx = 1,
  help_open = false,
  line_map = {},
  live_augroup = nil,
}
local ns = vim.api.nvim_create_namespace("ServiceManager")
local tooltip_ns = vim.api.nvim_create_namespace("ServiceManagerTooltip")

renderer.init(ui, ns)
actions.init(ui, tooltip_ns, renderer.render)

local function set_keymaps()
  local keymap_opts = { buffer = ui.buf, nowait = true, silent = true }
  local function map(k, fn)
    vim.keymap.set("n", k, fn, keymap_opts)
  end

  map("q", M.close)
  map("<Esc>", M.close)
  map("g?", renderer.toggle_help)
  map("<Space>", actions.do_toggle)
  map("<CR>", actions.do_toggle)
  map("i", actions.do_install)
  map("<Tab>", function()
    actions.switch_tab((ui.category_idx % #cfg.service_categories) + 1)
  end)
  map("<S-Tab>", function()
    actions.switch_tab(((ui.category_idx - 2) % #cfg.service_categories) + 1)
  end)
  map("[", function()
    actions.do_reorder(-1)
  end)
  map("]", function()
    actions.do_reorder(1)
  end)
  map("K", actions.show_tooltip_at_cursor)

  for i = 1, #cfg.service_categories do
    map(tostring(i), function()
      actions.switch_tab(i)
    end)
  end
end

function M.open()
  if ui.win and vim.api.nvim_win_is_valid(ui.win) then
    vim.api.nvim_set_current_win(ui.win)
    return
  end

  ui.buf = vim.api.nvim_create_buf(false, true)
  vim.bo[ui.buf].filetype = "ServiceManager"
  vim.bo[ui.buf].bufhidden = "wipe"

  ui.win = vim.api.nvim_open_win(ui.buf, true, renderer.make_win_cfg())
  vim.wo[ui.win].cursorline = true
  vim.wo[ui.win].wrap = false
  vim.wo[ui.win].number = false
  vim.wo[ui.win].relativenumber = false

  set_keymaps()
  renderer.start_live_update()

  vim.api.nvim_create_autocmd("WinClosed", {
    buffer = ui.buf,
    once = true,
    callback = function()
      renderer.stop_live_update()
      ui.win = nil
      ui.buf = nil
    end,
  })

  renderer.render()

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
