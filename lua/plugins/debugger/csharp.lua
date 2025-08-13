local M = {}

M.setup = function()
  local dap = require("plugins.debugger.shared").dap

  dap.adapters["netcoredbg"] = {
    type = "executable",
    command = vim.fn.exepath("netcoredbg"),
    args = { "--interpreter=vscode" },
    options = {
      detached = false,
    },
  }

  for _, lang in ipairs({ "cs", "fsharp", "vb" }) do
    dap.configurations[lang] = {
      {
        type = "netcoredbg",
        name = "Launch file",
        request = "launch",
        ---@diagnostic disable-next-line: redundant-parameter
        program = function()
          return vim.fn.input("Path to dll: ", vim.fn.getcwd() .. "/", "file")
        end,
        cwd = "${workspaceFolder}",
      },
    }
  end
end

return M
