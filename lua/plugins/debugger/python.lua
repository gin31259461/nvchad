local M = {}

local get_venv_path = function()
  local venv_path = os.getenv("VIRTUAL_ENV")

  if venv_path == "" or venv_path == nil then
    return ""
  end

  return vim.fs.normalize(venv_path)
end

local get_python_path = function()
  local venv_path = get_venv_path()

  if venv_path == "" then
    return ""
  end

  local executable_python_path = ""

  if NvChad.shell.is_win() then
    executable_python_path = venv_path .. "/Scripts/pythonw.exe"
  else
    executable_python_path = venv_path .. "/bin/python"
  end

  return executable_python_path
end

local debugpy_exists = function()
  local venv_path = get_venv_path()

  if NvChad.shell.is_win() then
    venv_path = venv_path .. "/Scripts/debugpy.exe"
  else
    venv_path = venv_path .. "/bin/debugpy"
  end

  return vim.fn.filereadable(venv_path)
end

-- need debugpy to be installed in .venv
M.setup = function()
  local dap = require("dap")

  dap.adapters.python = function(callback, config)
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
    elseif config.request == "launch" then
      local command = get_python_path()

      if command == "" then
        vim.notify("venv has not been activated", vim.log.levels.WARN)
        return
      end

      if debugpy_exists() == 0 then
        vim.notify("debugpy not found in venv, please install debugpy in venv", vim.log.levels.WARN)
        return
      end

      callback({
        type = "executable",
        command = command,
        args = { "-m", "debugpy.adapter" },
        options = {
          source_filetype = "python",
        },
      })
    end
  end

  -- Options below are for debugpy, see https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings for supported options
  dap.configurations.python = {
    {
      type = "python",
      request = "launch",
      name = "Launch Debugpy",
      program = "${file}",
    },
  }
end

return M
