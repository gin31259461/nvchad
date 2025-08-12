local M = {}

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

return M
