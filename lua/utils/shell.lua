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
    -- refer to https://www.reddit.com/r/neovim/comments/1crdv93/neovim_on_windows_using_windows_terminal_and/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
    vim.o.shellcmdflag =
      "-NoLogo -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;"
    vim.o.shellredir = "2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode"
    vim.o.shellpipe = "2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode"
    vim.o.shellquote = ""
    vim.o.shellxquote = ""

    -- this option only modifiable in MS-Windows, so set value here
    vim.o.shellslash = true
  else
    vim.o.shellcmdflag = "-c"
    vim.o.shellquote = ""
    vim.o.shellxquote = ""
  end
end

return M
