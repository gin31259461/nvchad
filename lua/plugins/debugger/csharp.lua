local M = {}

M.setup = function()
  local dap = require("dap")

  dap.adapters.netcoredbg = function(callback, config)
    local dll_path = vim.fn.input("Path to dll: ", vim.fn.getcwd() .. "/bin/Debug/", "file")

    if config.request == "launch" then
      callback({
        type = "executable",
        command = vim.fn.exepath("netcoredbg"),
        args = { "--interpreter=cli", "--", dll_path },
      })
    end
  end

  for _, lang in ipairs({ "cs", "fsharp", "vb" }) do
    ---@type dap.Configuration[]
    dap.configurations[lang] = {
      {
        type = "netcoredbg",
        name = "Launch .NET Core App",
        request = "launch",
      },
    }
  end
end

return M
