-- FIX: statusline diagnostics missing on idle buffer open
vim.api.nvim_create_autocmd({ "DiagnosticChanged" }, {
  pattern = "*",
  callback = function()
    vim.cmd("redrawstatus")
  end,
})
