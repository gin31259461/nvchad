local M = { harpoon = {} }

M.harpoon.highlight_current_file = function()
  return {
    UI_CREATE = function(cx)
      for line_number, file in pairs(cx.contents) do
        if cx.current_file ~= "" and string.find(file, cx.current_file, 1, true) then
          -- highlight the harpoon menu line that corresponds to the current buffer
          vim.api.nvim_buf_add_highlight(cx.bufnr, -1, "St_NormalModeSep", line_number - 1, 0, -1)
          -- set the position of the cursor in the harpoon menu to the start of the current buffer line
          vim.api.nvim_win_set_cursor(cx.win_id, { line_number, 0 })
        end
      end
    end,
  }
end

---@param path string
---@param opts? {has_hl?: boolean}
M.get_file_icon = function(path, opts)
  opts = opts or {}

  local web_devicons_present, web_devicons = pcall(require, "nvim-web-devicons")
  if not web_devicons_present then
    return ""
  end

  local filename = vim.fn.fnamemodify(path, ":t")
  local icon = "󰈚 "
  local devicon = ""
  local devicon_hl_name = ""

  if filename ~= "" then
    devicon, devicon_hl_name = web_devicons.get_icon(filename, filename:match("%.([^%.]+)$"))
    icon = (devicon or "")
  end

  if opts.has_hl then
    icon = string.format("%%#%s#", devicon_hl_name) .. icon .. "%*"
  end

  return icon
end

M.check_toggle_nvterm = function()
  local current_ft = vim.bo.filetype

  if current_ft:match("NvTerm_") or not M.win_is_floating() then
    return true
  end

  return false
end

---@param winid? integer
---@return boolean
M.win_is_floating = function(winid)
  winid = winid or 0
  local cfg = vim.api.nvim_win_get_config(winid)
  return cfg.relative ~= ""
end

return M
