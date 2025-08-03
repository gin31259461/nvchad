local M = {}

M.ignore_ft = { "neo%-tree", "nvdash", "NvTerm_", "trouble" }

M.if_ignore_ft = function()
  local current_ft = vim.bo.filetype

  for _, v in ipairs(M.ignore_ft) do
    if current_ft:match(v) then
      return true
    end
  end

  return false
end

--- @param symbols string
--- @param length number
--- @return string
M.pretty_symbol_path = function(symbols, length)
  -- symbol = icon + name (include hl)
  local parts = {}
  for s in symbols:gmatch("%%#.-%%%*%%#.-%%%*") do
    table.insert(parts, s)
  end

  local sep = "  "

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

  local relative_path = nvim.root.pretty_path(3)
  local dir = vim.fs.dirname(relative_path)

  local icon = "󰈚 "
  local filename = vim.fn.expand("%:t")
  filename = (filename == "" and "Empty") or filename

  local web_devicons_present, web_devicons = pcall(require, "nvim-web-devicons")

  if filename ~= "Empty" and web_devicons_present then
    local devicon, devicon_hl_name = web_devicons.get_icon(filename, filename:match("%.([^%.]+)$"))
    icon = string.format("%%#%s#", devicon_hl_name) .. (devicon or "") .. " " .. nvim.hl.statusline.text
  elseif filename == "Empty" then
    icon = nvim.hl.statusline.file .. icon
  end

  icon = "  " .. icon
  filename = nvim.hl.statusline.file .. filename .. nvim.hl.statusline.text

  if dir == "." then
    return icon .. filename
  end

  return icon .. nvim.hl.statusline.text .. dir .. "/" .. filename
end

M.state = { lsp_symbols = nil }

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
      return "  " .. M.pretty_symbol_path(symbols, 3)
    end
  end

  return ""
end

return M
