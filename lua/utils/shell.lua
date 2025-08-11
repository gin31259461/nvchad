local M = {}

M.is_linux = function()
  return vim.uv.os_uname().sysname:find("Linux") ~= nil
end

M.is_win = function()
  return vim.uv.os_uname().sysname:find("Windows") ~= nil
end

M.setup = function()
  if M.is_win() then
    vim.o.shell = vim.fn.has("win64") and "powershell.exe" or "pwsh.exe"
    vim.o.shellcmdflag = "-NoLogo -ExecutionPolicy RemoteSigned"
    vim.o.shellredir = "2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode"
    vim.o.shellpipe = "2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode"
    vim.o.shellquote = ""
    vim.o.shellxquote = '"'
  end
end

return M
