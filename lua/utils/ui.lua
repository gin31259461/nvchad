local M = { harpoon = {} }

M.get_neo_tree_width = function()
  local winid = nil
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local bufname = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win))
    if bufname:match("neo%-tree filesystem") or bufname:match("neo%-tree") then
      winid = win
      break
    end
  end

  if winid then
    return vim.api.nvim_win_get_width(winid)
  else
    return 0
  end
end

M.tree_offset = function()
  local w = M.get_neo_tree_width()
  return w == 0 and "" or "%#NeoTreeNormal#" .. string.rep(" ", w) .. "%#NeoTreeWinSeparator#" .. "│"
end

M.harpoon.short_path_length = 8

M.harpoon.highlight_current_file = function()
  return {
    UI_CREATE = function(cx)
      for line_number, file in pairs(cx.contents) do
        local short_path =
          NvChad.path.pretty_path(cx.current_file, { length = M.harpoon.short_path_length, only_cwd = true })
        if short_path ~= "" and string.find(file, short_path, 1, true) then
          -- highlight the harpoon menu line that corresponds to the current buffer
          local line = vim.api.nvim_buf_get_lines(cx.bufnr, line_number - 1, line_number, false)[1]

          vim.api.nvim_buf_set_extmark(
            cx.bufnr,
            vim.api.nvim_create_namespace("harpoon"),
            line_number - 1,
            2,
            { end_col = #line, hl_group = "St_NormalModeSep" }
          )
          -- set the position of the cursor in the harpoon menu to the start of the current buffer line
          vim.api.nvim_win_set_cursor(cx.win_id, { line_number, 0 })
        end
      end
    end,
  }
end

---@param win_id integer
---@return integer
M.get_text_offset = function(win_id)
  return vim.fn.getwininfo(win_id)[1].textoff
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
