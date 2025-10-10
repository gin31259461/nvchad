-- installation guide: https://codeberg.org/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation
-- custom command of debug console: https://github.com/mfussenegger/nvim-dap/blob/a479e25ed5b5d331fb46ee4b9e160ff02ac64310/doc/dap.txt#L955

local available_lang = { "csharp", "python" }

---@type LazySpec[]
return {
  {
    "mfussenegger/nvim-dap",
    event = { "VeryLazy" },
    opts = function()
      for _, v in ipairs(available_lang) do
        pcall(function()
          require("plugins.debugger." .. v).setup()
        end)
      end
    end,
    config = function() end,
    keys = {
      {
        "<leader>db",
        "<cmd>DapToggleBreakpoint<CR>",
        desc = "DAP Toggle Breakpoint",
      },
      {
        "<leader>dn",
        "<cmd>DapNew<CR>",
        desc = "DAP New Session",
      },
      {
        "<leader>dr",
        "<cmd>DapToggleRepl<CR>",
        desc = "DAP Toggle Repl",
      },

      {
        "<leader>dc",
        "<cmd>DapContinue<CR>",
        desc = "DAP Continue",
      },
      {
        "<leader>dl",
        "<cmd>DapShowLog<CR>",
        desc = "DAP Show Log",
      },
    },
  },

  {
    "rcarriga/nvim-dap-ui",
    event = "VeryLazy",
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
    opts = {},
    config = function(_, opts)
      local dap = require("dap")
      local dapui = require("dapui")

      dapui.setup(opts)

      dap.listeners.before.attach.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.launch.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated.dapui_config = function()
        dapui.close()
      end
      dap.listeners.before.event_exited.dapui_config = function()
        dapui.close()
      end
    end,
  },
}
