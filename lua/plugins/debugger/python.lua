local M = {}

-- need debugpy to be installed in .venv
M.setup = function()
  local dap = require("plugins.debugger.shared").dap
  local root = require("plugins.debugger.shared").root

  local executable_python_path = "/.venv/bin/python"

  if NvChad.shell.is_win() then
    executable_python_path = "/.venv/Scripts/pythonw.exe"
  end

  executable_python_path = root .. executable_python_path

  if not dap.adapters["python"] then
    dap.adapters["python"] = function(callback, config)
      if config.request == "attach" then
        ---@diagnostic disable-next-line: undefined-field
        local port = (config.connect or config).port
        ---@diagnostic disable-next-line: undefined-field
        local host = (config.connect or config).host or "127.0.0.1"
        callback({
          type = "server",
          port = assert(port, "`connect.port` is required for a python `attach` configuration"),
          host = host,
          options = {
            source_filetype = "python",
          },
        })
      else
        callback({
          type = "executable",
          command = executable_python_path,
          args = { "-m", "debugpy.adapter" },
          options = {
            source_filetype = "python",
          },
        })
      end
    end
  end

  if not dap.configurations["python"] then
    dap.configurations["python"] = {
      {
        -- The first three options are required by nvim-dap
        type = "python", -- the type here established the link to the adapter definition: `dap.adapters.python`
        request = "launch",
        name = "Launch file",

        -- Options below are for debugpy, see https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings for supported options

        program = "${file}", -- This configuration will launch the current file if used.
        pythonPath = function()
          -- debugpy supports launching an application with a different interpreter then the one used to launch debugpy itself.
          -- The code below looks for a `venv` or `.venv` folder in the current directly and uses the python within.
          -- You could adapt this - to for example use the `VIRTUAL_ENV` environment variable.

          return executable_python_path
        end,
      },
    }
  end
end

return M
