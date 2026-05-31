-- FIX: statusline diagnostics missing on idle buffer open
vim.api.nvim_create_autocmd("DiagnosticChanged", {
  group = vim.api.nvim_create_augroup(
    "UserDiagnosticChanged",
    { clear = true }
  ),
  callback = function()
    vim.cmd("redrawstatus")
  end,
  desc = "Redraw statusline when diagnostics change",
})
