local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

-- FIX: statusline diagnostics missing on idle buffer open
autocmd("DiagnosticChanged", {
  group = augroup("UserDiagnosticChanged", { clear = true }),
  callback = function()
    vim.cmd("redrawstatus")
  end,
  desc = "Redraw statusline when diagnostics change",
})

local function has_listed_unnamed_buffer()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if
      vim.api.nvim_buf_is_loaded(buf)
      and vim.bo[buf].buflisted
      and vim.bo[buf].buftype == ""
      and vim.api.nvim_buf_get_name(buf) == ""
    then
      return true
    end
  end

  return false
end

autocmd("VimEnter", {
  group = augroup("StartupNoNameBuffer", { clear = true }),
  callback = function(data)
    if vim.fn.argc() > 0 or data.file ~= "" then
      return
    end

    vim.schedule(function()
      if has_listed_unnamed_buffer() then
        return
      end

      vim.api.nvim_create_buf(true, false)
    end)
  end,
  desc = "Create an unnamed buffer behind the startup dashboard",
})

autocmd("VimEnter", {
  group = augroup("AutoSetDir", { clear = true }),
  callback = function(data)
    if vim.fn.isdirectory(data.file) ~= 1 then
      return
    end

    vim.api.nvim_set_current_dir(data.file)

    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(data.buf) then
        vim.api.nvim_buf_delete(data.buf, { force = true })
      end
    end)
  end,
  desc = "cd into directory when `nvim <dir>` is used",
})
