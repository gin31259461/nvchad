local M = {}

local fs = require("utils.fs")
local ui = require("utils.ui")
local config = require("config")

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

local symbol_separator = "  "

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
    return table.concat(parts, symbol_separator)
  end

  local short_parts = { parts[1], "…" }
  vim.list_extend(
    short_parts,
    vim.list_slice(parts, #parts - length + 2, #parts)
  )

  return table.concat(short_parts, symbol_separator)
end

---@return string
M.file_path = function()
  if M.is_ignore_ft() then
    return ""
  end

  local relative_path = fs.pretty_path(nil, { only_cwd = true })
  local dir = vim.fs.dirname(relative_path)
  local filename = vim.fn.fnamemodify(relative_path, ":t")
  local icon = "%#St_file_open#" .. "󰈚"

  if filename ~= "" then
    icon = ui.get_file_icon(filename, { has_hl = true })
  end

  filename = (filename == "" and "Empty") or filename

  -- set hl and indent
  icon = icon .. " "
  filename = "%#St_file_open#" .. filename

  if dir == "." then
    return icon .. filename
  end

  return icon .. "%#St_file_path#" .. dir .. "/" .. filename
end

---@return string
M.symbols = function()
  if M.is_ignore_ft() then
    return ""
  end

  local nvchad_utils_present, nvchad_utils = pcall(require, "nvchad.stl.utils")

  if
    nvchad_utils_present
    and nvchad_utils.state.lsp_msg == ""
    and M.state.symbols
    and type(M.state.symbols) == "function"
  then
    local symbols = M.state.symbols()

    if symbols ~= "" then
      return "%#St_symbols_sep#"
        .. symbol_separator
        .. M.pretty_symbol_path(symbols, 3)
    end
  end

  return ""
end

-------------------- all state --------------------
---@class StatuslineState
---@field symbols? function function to get the current LSP symbols for the statusline

--- store state in global variable to persist across reloads
---@type StatuslineState
_G.statusline_state = _G.statusline_state or { symbols = nil }
M.state = _G.statusline_state

M.set_symbols_state = function()
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
    hl_group = "St_symbols",
  })

  M.state.symbols = symbols.get
end

-- call this setup after all plugins are loaded
M.setup = function()
  M.set_symbols_state()
end

return M
