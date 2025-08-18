local M = {}

M.ignore_ft = { "neo%-tree", "nvdash", "NvTerm_", "trouble", "noice" }

M.stbufnr = function()
  return vim.api.nvim_win_get_buf(vim.g.statusline_winid or 0)
end

M.if_ignore_ft = function()
  local current_ft = vim.bo.filetype

  for _, v in ipairs(M.ignore_ft) do
    if current_ft:match(v) then
      return true
    end
  end

  return false
end

-- "  "
local sep = "  "

--- @param symbols string
--- @param length number
--- @return string
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
  vim.list_extend(short_parts, vim.list_slice(parts, #parts - length + 2, #parts))

  return table.concat(short_parts, sep)
end

M.path = function()
  if M.if_ignore_ft() then
    return ""
  end

  local relative_path = NvChad.root.pretty_path(nil, { only_cwd = true })
  local dir = vim.fs.dirname(relative_path)
  local filename = vim.fn.fnamemodify(relative_path, ":t")
  local icon = NvChad.hl.statusline.file .. "󰈚 "

  if filename ~= "" then
    icon = NvChad.ui.get_file_icon(filename, { has_hl = true })
  end

  filename = (filename == "" and "Empty") or filename

  -- set hl and indent
  icon = "  " .. icon .. " "
  filename = NvChad.hl.statusline.trouble_text .. filename

  if dir == "." then
    return icon .. filename
  end

  return icon .. NvChad.hl.statusline.text .. dir .. "/" .. filename
end

M.lsp_symbols = function()
  if M.if_ignore_ft() then
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
      return NvChad.hl.statusline.file .. sep .. M.pretty_symbol_path(symbols, 3)
    end
  end

  return ""
end

M.lsp = function()
  local hl = "%#St_NormalModeSep#"
  if rawget(vim, "lsp") then
    for _, client in ipairs(vim.lsp.get_clients()) do
      if client.attached_buffers[M.stbufnr()] then
        -- return (vim.o.columns > 100 and "   LSP ~ " .. client.name .. " ") or "   LSP "
        return hl .. "   LSP "
      end
    end
  end

  return ""
end

M.mode = function()
  if type(M.state.mode) == "function" then
    return M.state.mode()
  end

  return ""
end

M.git = function()
  if not vim.b[M.stbufnr()].gitsigns_head or vim.b[M.stbufnr()].gitsigns_git_status then
    return ""
  end

  local git_status = vim.b[M.stbufnr()].gitsigns_status_dict

  local added = (git_status.added and git_status.added ~= 0) and ("  " .. git_status.added) or ""
  local changed = (git_status.changed and git_status.changed ~= 0) and ("  " .. git_status.changed) or ""
  local removed = (git_status.removed and git_status.removed ~= 0) and ("  " .. git_status.removed) or ""
  -- local branch_name = " " .. git_status.head
  local branch_name = " "

  return " " .. branch_name .. added .. changed .. removed
end

-------------------- all state --------------------
M.state = { lsp_symbols = nil, mode = nil }

M.set_lsp_symbols_state = function()
  local trouble = require("trouble")
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
  local config = require("nvconfig").ui.statusline
  local sep_style = config.separator_style
  local utils = require("nvchad.stl.utils")

  local sep_icons = utils.separators
  local separators = (type(sep_style) == "table" and sep_style) or sep_icons[sep_style]

  -- local sep_l = separators["left"]
  local sep_r = separators["right"]

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

    local current_mode = "%#St_" .. modes[m][2] .. "Mode#  " .. modes[m][1]
    local mode_sep1 = "%#St_" .. modes[m][2] .. "ModeSep#" .. sep_r

    -- return current_mode .. mode_sep1 .. "%#ST_EmptySpace#" .. sep_r
    return current_mode .. recording .. mode_sep1
  end
end

-- call this setup after all plugins are loaded
M.setup = function()
  M.set_mode_state()
  M.set_lsp_symbols_state()
end

return M
