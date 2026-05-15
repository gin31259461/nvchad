local M = {}

local fs = require("utils.fs")
local hl = require("utils.hl")
local ui = require("utils.ui")
local config = require("config")

---@class StatuslineMarginOpt
---@field left? integer number of spaces to insert on the left side of the components
---@field right? integer number of spaces to insert on the right side of the components

---@class StatuslineComponentOpt
---@field gap? integer number of spaces to insert between components
---@field separator? string separator to use between components
---@field margin? StatuslineMarginOpt number of spaces to insert on the left and right sides of the components

---@param components table
---@param opts StatuslineComponentOpt
M.merge_components = function(components, opts)
  local gap = opts.gap or 1
  local margin =
    vim.tbl_deep_extend("keep", opts.margin or {}, { left = 0, right = 0 })
  local margin_left = string.rep(" ", margin.left)
  local margin_right = string.rep(" ", margin.right)

  -- filter components that are empty after stripping highlight groups (%#...#)
  local filtered_components = vim.tbl_filter(function(c)
    return c:gsub("%%#[^#]*#", "") ~= ""
  end, components)
  return margin_left
    .. table.concat(filtered_components, string.rep(" ", gap))
    .. margin_right
end

---@return integer
M.get_statusline_buf = function()
  return vim.api.nvim_win_get_buf(vim.g.statusline_winid or 0)
end

---@return boolean
M.is_ignore_ft = function()
  local current_ft = vim.bo.filetype

  for _, v in ipairs(config.statusline_ignored) do
    if current_ft:match(v) then
      return true
    end
  end

  return false
end

local sep = "  "

---@param symbols string
---@param length number
---@return string
M.pretty_symbol_path = function(symbols, length)
  -- symbol = icon + name (include hl)
  local parts = {}
  for s in symbols:gmatch("%%#.-%%%*%%#.-%%%*") do
    table.insert(parts, s)
  end

  if #parts <= length then
    return table.concat(parts, sep)
  end

  local short_parts = { parts[1], "…" }
  vim.list_extend(
    short_parts,
    vim.list_slice(parts, #parts - length + 2, #parts)
  )

  return table.concat(short_parts, sep)
end

---@return string
M.path = function()
  if M.is_ignore_ft() then
    return ""
  end

  local relative_path = fs.pretty_path(nil, { only_cwd = true })
  local dir = vim.fs.dirname(relative_path)
  local filename = vim.fn.fnamemodify(relative_path, ":t")
  local icon = hl.statusline.current_file .. "󰈚"

  if filename ~= "" then
    icon = ui.get_file_icon(filename, { has_hl = true })
  end

  filename = (filename == "" and "Empty") or filename

  -- set hl and indent
  icon = icon .. " "
  filename = hl.statusline.current_file .. filename

  if dir == "." then
    return icon .. filename
  end

  return icon .. hl.statusline.text .. dir .. "/" .. filename
end

---@return string
M.lsp_symbols = function()
  if M.is_ignore_ft() then
    return ""
  end

  local nvchad_utils_present, nvchad_utils = pcall(require, "nvchad.stl.utils")

  if
    nvchad_utils_present
    and nvchad_utils.state.lsp_msg == ""
    and M.state.lsp_symbols
    and type(M.state.lsp_symbols) == "function"
  then
    local symbols = M.state.lsp_symbols()

    if symbols ~= "" then
      return hl.statusline.current_file
        .. sep
        .. M.pretty_symbol_path(symbols, 3)
    end
  end

  return ""
end

---@return string
M.current_lsp = function()
  if rawget(vim, "lsp") then
    local copilot = ""
    local lsp_client = ""

    for _, client in ipairs(vim.lsp.get_clients()) do
      if client.attached_buffers[M.get_statusline_buf()] then
        if client.name == "copilot" then
          copilot = copilot .. " "
        else
          lsp_client = vim.o.columns > 100 and "  LSP ~ " .. client.name
            or "  LSP"
        end
      end
    end

    return M.merge_components({
      hl.statusline.copilot .. copilot,
      hl.statusline.active_context .. lsp_client,
    }, { gap = 1, margin = { right = 1 } })
  end

  return ""
end

---@return string
M.mode = function()
  if type(M.state.mode) == "function" then
    return M.state.mode()
  end

  return ""
end

---@return string
M.git = function()
  if
    not vim.b[M.get_statusline_buf()].gitsigns_head
    or vim.b[M.get_statusline_buf()].gitsigns_git_status
  then
    return ""
  end

  local git_status = vim.b[M.get_statusline_buf()].gitsigns_status_dict

  local added = (git_status.added and git_status.added ~= 0)
      and (" " .. git_status.added)
    or ""
  local changed = (git_status.changed and git_status.changed ~= 0)
      and (" " .. git_status.changed)
    or ""
  local removed = (git_status.removed and git_status.removed ~= 0)
      and (" " .. git_status.removed)
    or ""

  local branch_name = " " .. git_status.head

  return M.merge_components(
    { branch_name, added, changed, removed },
    { gap = 1, margin = { left = 1 } }
  )
end

---@return string
M.break_point = function()
  return "  %<"
end

-------------------- all state --------------------
---@class StatuslineState
---@field lsp_symbols? function function to get the current LSP symbols for the statusline
---@field mode? function function to get the current mode for the statusline

--- store state in global variable to persist across reloads
---@type StatuslineState
_G.statusline_state = _G.statusline_state or { lsp_symbols = nil, mode = nil }
M.state = _G.statusline_state

M.set_lsp_symbols_state = function()
  local ok, trouble = pcall(require, "trouble")
  if not ok then
    return
  end
  local symbols = trouble.statusline({
    mode = "symbols",
    groups = {},
    title = false,
    filter = { range = true },
    format = "{kind_icon}{symbol.name:Normal}",
    hl_group = "@statusline.symbols",
  })

  M.state.lsp_symbols = symbols.get
end

M.set_mode_state = function()
  local ok, utils = pcall(require, "nvchad.stl.utils")
  if not ok then
    return
  end

  M.state.mode = function()
    if not utils.is_activewin() then
      return ""
    end

    local modes = utils.modes
    local m = vim.api.nvim_get_mode().mode
    local recording = vim.fn.reg_recording()

    if #recording > 0 then
      recording = " @" .. recording
    end

    local mode_sep_left = "%#St_"
      .. modes[m][2]
      .. "ModeSep#"
      .. config.icons.separators.round.left
    local current_mode = "%#St_"
      .. modes[m][2]
      .. "Mode#"
      .. " "
      .. modes[m][1]
    local mode_sep_right = "%#St_"
      .. modes[m][2]
      .. "ModeSep#"
      .. config.icons.separators.round.right

    return mode_sep_left .. current_mode .. recording .. mode_sep_right
  end
end

-- call this setup after all plugins are loaded
M.setup = function()
  M.set_mode_state()
  M.set_lsp_symbols_state()
end

return M
