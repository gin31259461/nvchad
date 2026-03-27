-- installation guide: https://codeberg.org/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation
-- custom command of debug console: https://github.com/mfussenegger/nvim-dap/blob/a479e25ed5b5d331fb46ee4b9e160ff02ac64310/doc/dap.txt#L955

-- NOTE: launch.json:
-- refer to: https://github.com/mfussenegger/nvim-dap/blob/master/doc/dap.txt#L327-L331
-- attributes: https://code.visualstudio.com/docs/debugtest/debugging-configuration#_launchjson-attributes

---@type LazySpec[]
return {
  {
    "mfussenegger/nvim-dap",
    event = { "VeryLazy" },
    opts = function()
      local config = require("plugins.debugger.config")
      local dap = require("dap")

      for name, adapter in pairs(config.adapters) do
        dap.adapters[name] = adapter
      end

      for ft, configurations in pairs(config.configurations) do
        dap.configurations[ft] = configurations
      end
    end,
    config = function() end,
    keys = {
      {
        "<leader>dt",
        "<cmd>DapToggleBreakpoint<CR>",
        desc = "DAP Toggle Breakpoint",
      },
      {
        "<leader>ds",
        "<cmd>DapNew<CR>",
        desc = "DAP New Session",
      },
      {
        "<leader>dR",
        "<cmd>DapToggleRepl<CR>",
        desc = "DAP Toggle REPL",
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
      {
        "<leader>dn",
        "<cmd>DapStepOver<CR>",
        desc = "DAP Step Over",
      },
      {
        "<leader>di",
        "<cmd>DapStepInto<CR>",
        desc = "DAP Step Into",
      },
      {
        "<leader>do",
        "<cmd>DapStepOut<CR>",
        desc = "DAP Step Out",
      },
      {
        "<leader>dw",
        "<cmd>DapViewWatch<CR>",
        desc = "DAP Open Watch window",
      },
    },
  },

  -- https://github.com/rcarriga/nvim-dap-ui
  {
    "rcarriga/nvim-dap-ui",
    event = "VeryLazy",
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
    config = function(_, opts)
      local dap = require("dap")
      local dapui = require("dapui")

      dapui.setup(opts)
      dap.set_log_level("TRACE")

      -- dap.listeners.after.event_initialized["dapui_config"] = function()
      --   dapui.open({})
      -- end
      dap.listeners.before.terminate["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end

      vim.keymap.set("n", "<leader>du", function()
        dapui.toggle()
      end, { desc = "DAP Toggle UI" })
      vim.keymap.set("n", "<leader>dr", function()
        dap.restart()
      end, { desc = "DAP Restart" })
    end,
  },
}
