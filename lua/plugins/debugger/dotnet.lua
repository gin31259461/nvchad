local M = {}

local function pick_dll()
  return vim.fn.input("Path to dll: ", vim.fn.getcwd() .. "/bin/Debug/", "file")
end

M.setup = function()
  local dap = require("dap")
  local command = vim.fn.exepath("netcoredbg")

  dap.adapters.dotnet = function(callback, config)
    callback({
      type = "executable",
      command = command,
      args = { "--interpreter=cli", "--", "dotnet", pick_dll() },
    })
  end

  ---@type dap.Configuration[]
  dap.configurations.cs = {
    {
      type = "dotnet",
      name = "launch .net core app",
      request = "launch",
    },
  }
end

return M
