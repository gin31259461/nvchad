local M = {}

M.path = function()
  local current_ft = vim.bo.filetype
  local ignore_ft = { "neo%-tree", "nvdash", "NvTerm_", "trouble" }

  for _, v in ipairs(ignore_ft) do
    if current_ft:match(v) then
      return ""
    end
  end

  local relative_path = nvim.root.pretty_path(6)
  local dir = vim.fs.dirname(relative_path)

  local icon = "󰈚 "
  local filename = vim.fn.expand("%:t")
  filename = (filename == "" and "Empty") or filename

  if filename ~= "Empty" then
    local devicon, devicon_hl_name = require("nvim-web-devicons").get_icon(filename, filename:match("%.([^%.]+)$"))
    icon = string.format("%%#%s#", devicon_hl_name) .. (devicon or "") .. " " .. nvim.hl.statusline.text
  end

  icon = "  " .. icon
  filename = nvim.hl.statusline.current_file .. filename .. nvim.hl.statusline.text

  if dir == "." then
    return icon .. filename
  end

  return icon .. nvim.hl.statusline.text .. dir .. "/" .. filename
end

return M
