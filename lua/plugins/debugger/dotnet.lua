local M = {}

local function pick_dll()
  return vim.fn.input("Path to dll: ", vim.fn.getcwd() .. "/bin/Debug/", "file")
end

local function get_dotnet_project_name()
  local csproj_files = vim.fn.glob("*.csproj", false, true)

  if vim.tbl_isempty(csproj_files) then
    return ""
  end

  return vim.fn.getcwd() .. "/bin/Debug/" .. vim.fn.fnamemodify(csproj_files[1], ":t:r") .. ".dll"
end

M.setup = function()
  local dap = require("dap")
  local executable = "netcoredbg"

  if NvChad.shell.is_win() then
    -- FIX: The netcoredbg executable must have the .exe extension on Windows, not .cmd
    -- this path will not work because it's .cmd: vim.fn.exepath("netcoredbg")
    executable = vim.fn.stdpath("data") .. "/mason/packages/netcoredbg/netcoredbg/" .. executable .. ".exe"
  end

  dap.adapters.coreclr = function(callback, config)
    callback({
      type = "executable",
      command = executable,
      args = { "--interpreter=vscode" },
    })
  end

  dap.configurations.cs = {
    {
      type = "coreclr",
      name = "launch .net core app (auto choose dll)",
      request = "launch",
      program = get_dotnet_project_name,
      cwd = vim.fn.getcwd(),
      justMyCode = false,
      env = {
        ASPNETCORE_ENVIRONMENT = "Development",
      },
    },

    {
      type = "coreclr",
      name = "launch .net core app (choose dll)",
      request = "launch",
      program = pick_dll,
      cwd = vim.fn.getcwd(),
      justMyCode = false,
      env = {
        ASPNETCORE_ENVIRONMENT = "Development",
      },
    },
  }
end

return M
