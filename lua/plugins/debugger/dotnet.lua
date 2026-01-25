-- NOTE: It also requires the correct .NET runtime based on the .NET version used in your project. 

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

  if Core.shell.is_win() then
    -- FIX: The netcoredbg executable must have the .exe extension on Windows, not .cmd
    -- this path will not work because it's .cmd: vim.fn.exepath("netcoredbg")
    executable = vim.fn.stdpath("data") .. "/mason/packages/netcoredbg/netcoredbg/" .. executable .. ".exe"
  end

  dap.adapters.coreclr = function(callback, config)
    vim.notify("Building project", vim.log.levels.INFO, { title = "Dotnet" })
    local build_cmd = require("plugins.lsp.cmd.dotnet").get_build_cmd()

    vim.fn.jobstart(build_cmd, {
      -- refer to nvim doc: https://neovim.io/doc/user/job_control.html#on_exit
      on_exit = function(job_id, exit_code, event_type)
        if exit_code == 0 then
          vim.notify("Build project successfully", vim.log.levels.INFO, { title = "Dotnet" })

          callback({
            type = "executable",
            command = executable,
            args = { "--interpreter=vscode" },
          })
        else
          vim.notify("Error occur when build project", vim.log.levels.ERROR, { title = "Dotnet" })
        end
      end,
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
