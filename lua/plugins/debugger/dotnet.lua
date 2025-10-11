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

local function get_build_dotnet_project_cmd()
  return { "dotnet", "build", "-c", "Debug", "-o", vim.fn.getcwd() .. "/bin/Debug/" }
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
    vim.notify("building project", vim.log.levels.INFO, { title = "Dotnet" })
    local build_cmd = get_build_dotnet_project_cmd()

    vim.fn.jobstart(build_cmd, {
      on_exit = function(job_id, exit_code, event_type)
        if exit_code == 0 then
          vim.notify("build project successfully", vim.log.levels.INFO, { title = "Dotnet" })

          callback({
            type = "executable",
            command = executable,
            args = { "--interpreter=vscode" },
          })
        else
          vim.notify("error occur when build project", vim.log.levels.ERROR, { title = "Dotnet" })
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
