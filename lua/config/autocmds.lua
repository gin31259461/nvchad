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
