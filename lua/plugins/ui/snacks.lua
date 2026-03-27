local configs = require("configs")

-- https://github.com/folke/snacks.nvim?tab=readme-ov-file#-features
---@type LazySpec[]
return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,

    ---@type snacks.Config
    opts = {
      bigfile   = { enabled = true },
      explorer  = { enabled = true },
      indent    = { enabled = true },
      input     = { enabled = true },
      quickfile = { enabled = true },
      scope     = { enabled = true },
      scroll    = { enabled = true },
      statuscolumn = { enabled = true },
      words     = { enabled = true },
      lazygit   = {},

      -- reference: https://github.com/folke/snacks.nvim/discussions/111#discussioncomment-11986334
      dashboard = {
        enabled = true,
        preset = {
          header = require("configs.header").phantom_snack,
        },

        -- built-in sections: https://github.com/folke/snacks.nvim/blob/main/docs/dashboard.md#-features
        sections = {
          { section = "header", align = "center" },
          { pane = 2, section = "keys",         gap = 1, padding = 1 },
          { pane = 2, icon = " ", title = "Recent Files", section = "recent_files", indent = 2, padding = { 1, 1 } },
          { pane = 2, icon = " ", title = "Projects",    section = "projects",     indent = 2, padding = 1 },
          { pane = 2, section = "startup" },
        },
      },

      notifier = {
        enabled = true,
        top_down = false,
        margin = { bottom = 2 },
        timeout = 3000,
        filter = function(notif)
          for _, msg in ipairs(configs.ignore_msgs.notify) do
            if notif.msg:find(msg) then
              return false
            end
          end
          return true
        end,
      },

      picker = {
        enabled = true,
        win = {
          list = {
            wo = { wrap = false },
          },
          input = {
            keys = {
              ["<C-u>"] = { "preview_scroll_up",   mode = { "i", "n" } },
              ["<C-d>"] = { "preview_scroll_down",  mode = { "i", "n" } },
            },
          },
        },
      },
    },

    keys = {
      { "<leader>D",  function() require("snacks").dashboard()                                   end, desc = "Open Dashboard" },
      { "<leader>n",  function() require("snacks").picker.notifications()                        end, desc = "Notification History" },

      -- find
      { "<leader>fb", function() require("snacks").picker.buffers()                              end, desc = "Buffers" },
      { "<leader>fc", function() require("snacks").picker.files({ cwd = vim.fn.stdpath("config") }) end, desc = "Find Config File" },
      { "<leader>ff", function() require("snacks").picker.files()                                end, desc = "Find Files" },
      { "<leader>fg", function() require("snacks").picker.git_files()                            end, desc = "Find Git Files" },
      { "<leader>fp", function() require("snacks").picker.projects()                             end, desc = "Projects" },
      { "<leader>fr", function() require("snacks").picker.recent()                               end, desc = "Recent" },

      -- git
      { "<leader>gb", function() require("snacks").picker.git_branches()                        end, desc = "Git Branches" },
      { "<leader>gl", function() require("snacks").picker.git_log()                              end, desc = "Git Log" },
      { "<leader>gL", function() require("snacks").picker.git_log_line()                         end, desc = "Git Log Line" },
      { "<leader>gs", function() require("snacks").picker.git_status()                           end, desc = "Git Status" },
      { "<leader>gS", function() require("snacks").picker.git_stash()                            end, desc = "Git Stash" },
      { "<leader>gd", function() require("snacks").picker.git_diff()                             end, desc = "Git Diff (Hunks)" },
      { "<leader>gf", function() require("snacks").picker.git_log_file()                         end, desc = "Git Log File" },

      -- grep
      { "<leader>sb", function() require("snacks").picker.lines()                                end, desc = "Buffer Lines" },
      { "<leader>sB", function() require("snacks").picker.grep_buffers()                         end, desc = "Grep Open Buffers" },
      { "<leader>sg", function() require("snacks").picker.grep()                                  end, desc = "Grep" },
      { "<leader>sw", function() require("snacks").picker.grep_word()                             end, desc = "Visual selection or word", mode = { "n", "x" } },

      -- search
      { '<leader>s"', function() require("snacks").picker.registers()                            end, desc = "Registers" },
      { "<leader>s/", function() require("snacks").picker.search_history()                       end, desc = "Search History" },
      { "<leader>sa", function() require("snacks").picker.autocmds()                             end, desc = "Autocmds" },
      { "<leader>sc", function() require("snacks").picker.command_history()                      end, desc = "Command History" },
      { "<leader>sC", function() require("snacks").picker.commands()                             end, desc = "Commands" },
      { "<leader>sd", function() require("snacks").picker.diagnostics()                          end, desc = "Diagnostics" },
      { "<leader>sD", function() require("snacks").picker.diagnostics_buffer()                   end, desc = "Buffer Diagnostics" },
      { "<leader>sH", function() require("snacks").picker.highlights()                           end, desc = "Highlights" },
      { "<leader>si", function() require("snacks").picker.icons()                                end, desc = "Icons" },
      { "<leader>sj", function() require("snacks").picker.jumps()                                end, desc = "Jumps" },
      { "<leader>sk", function() require("snacks").picker.keymaps()                              end, desc = "Keymaps" },
      { "<leader>sl", function() require("snacks").picker.loclist()                              end, desc = "Location List" },
      { "<leader>sm", function() require("snacks").picker.marks()                                end, desc = "Marks" },
      { "<leader>sM", function() require("snacks").picker.man()                                  end, desc = "Man Pages" },
      { "<leader>sp", function() require("snacks").picker.lazy()                                 end, desc = "Search for Plugin Spec" },
      { "<leader>sq", function() require("snacks").picker.qflist()                               end, desc = "Quickfix List" },
      { "<leader>sR", function() require("snacks").picker.resume()                               end, desc = "Resume" },
      { "<leader>su", function() require("snacks").picker.undo()                                 end, desc = "Undo History" },

      -- other
      { "<leader>gg", function() require("snacks").lazygit()                                     end, desc = "Lazygit" },
    },

    config = function(_, opts)
      local snacks = require("snacks")
      local redraw_range = snacks.util.redraw_range

      -- Wrap to suppress invalid window id error popups
      snacks.util.redraw_range = function(...)
        pcall(redraw_range, ...)
      end

      snacks.setup(opts)
    end,
  },
}
