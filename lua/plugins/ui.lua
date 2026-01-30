---@type LazySpec[]
return {
  {
    "nvchad/ui",
    cond = false,
    lazy = false,
    config = function()
      require("nvchad")
    end,
  },

  {
    "gin31259461/nvchad-ui",
    lazy = false,
    config = function()
      require("nvchad")
    end,
  },

  {
    -- https://github.com/folke/snacks.nvim?tab=readme-ov-file#-features
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,

    ---@type snacks.Config
    opts = {
      bigfile = { enabled = true },

      -- reference: https://github.com/folke/snacks.nvim/discussions/111#discussioncomment-11986334
      dashboard = {
        enabled = true,
        preset = {
          header = require("configs.header").wolf_snack,
        },

        -- build-in: https://github.com/folke/snacks.nvim/blob/main/docs/dashboard.md#-features
        sections = {
          { section = "header", align = "center" },
          { pane = 2, section = "keys", gap = 1, padding = 1 },
          { pane = 2, icon = " ", title = "Recent Files", section = "recent_files", indent = 2, padding = { 1, 1 } },
          { pane = 2, icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1 },
          { pane = 2, section = "startup" },
        },
      },
      explorer = { enabled = true },
      indent = { enabled = true },
      input = { enabled = true },
      notifier = {
        enabled = true,
        top_down = false,
        margin = {
          bottom = 2,
        },
        timeout = 3000,
        filter = function(notif)
          for _, msg in ipairs(require("configs").ignore_msgs.notify) do
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
            wo = {
              wrap = false,
            },
          },
          input = {
            keys = {
              ["<C-u>"] = { "preview_scroll_up", mode = { "i", "n" } },
              ["<C-d>"] = { "preview_scroll_down", mode = { "i", "n" } },
            },
          },
        },
      },
      quickfile = { enabled = true },
      scope = { enabled = true },
      scroll = { enabled = true },
      statuscolumn = { enabled = true },
      words = { enabled = true },
      lazygit = {},
    },

    keys = {
      {
        "<leader>D",
        function()
          Core.snacks.dashboard()
        end,
        desc = "Open Dashboard",
      },

      -- Top pickers & Explorer
      {
        "<leader>n",
        function()
          Core.snacks.picker.notifications()
        end,
        desc = "Notification History",
      },

      -- find
      {
        "<leader>fb",
        function()
          Core.snacks.picker.buffers()
        end,
        desc = "Buffers",
      },
      {
        "<leader>fc",
        function()
          Core.snacks.picker.files({ cwd = vim.fn.stdpath("config") })
        end,
        desc = "Find Config File",
      },
      {
        "<leader>ff",
        function()
          Core.snacks.picker.files()
        end,
        desc = "Find Files",
      },
      {
        "<leader>fg",
        function()
          Core.snacks.picker.git_files()
        end,
        desc = "Find Git Files",
      },
      {
        "<leader>fp",
        function()
          Core.snacks.picker.projects()
        end,
        desc = "Projects",
      },
      {
        "<leader>fr",
        function()
          Core.snacks.picker.recent()
        end,
        desc = "Recent",
      },

      -- git
      {
        "<leader>gb",
        function()
          Core.snacks.picker.git_branches()
        end,
        desc = "Git Branches",
      },
      {
        "<leader>gl",
        function()
          Core.snacks.picker.git_log()
        end,
        desc = "Git Log",
      },
      {
        "<leader>gL",
        function()
          Core.snacks.picker.git_log_line()
        end,
        desc = "Git Log Line",
      },
      {
        "<leader>gs",
        function()
          Core.snacks.picker.git_status()
        end,
        desc = "Git Status",
      },
      {
        "<leader>gS",
        function()
          Core.snacks.picker.git_stash()
        end,
        desc = "Git Stash",
      },
      {
        "<leader>gd",
        function()
          Core.snacks.picker.git_diff()
        end,
        desc = "Git Diff (Hunks)",
      },
      {
        "<leader>gf",
        function()
          Core.snacks.picker.git_log_file()
        end,
        desc = "Git Log File",
      },
      -- Grep
      {
        "<leader>sb",
        function()
          Core.snacks.picker.lines()
        end,
        desc = "Buffer Lines",
      },
      {
        "<leader>sB",
        function()
          Core.snacks.picker.grep_buffers()
        end,
        desc = "Grep Open Buffers",
      },
      {
        "<leader>sg",
        function()
          Core.snacks.picker.grep()
        end,
        desc = "Grep",
      },
      {
        "<leader>sw",
        function()
          Core.snacks.picker.grep_word()
        end,
        desc = "Visual selection or word",
        mode = { "n", "x" },
      },

      -- search
      {
        '<leader>s"',
        function()
          Core.snacks.picker.registers()
        end,
        desc = "Registers",
      },
      {
        "<leader>s/",
        function()
          Core.snacks.picker.search_history()
        end,
        desc = "Search History",
      },
      {
        "<leader>sa",
        function()
          Core.snacks.picker.autocmds()
        end,
        desc = "Autocmds",
      },
      {
        "<leader>sc",
        function()
          Core.snacks.picker.command_history()
        end,
        desc = "Command History",
      },
      {
        "<leader>sC",
        function()
          Core.snacks.picker.commands()
        end,
        desc = "Commands",
      },
      {
        "<leader>sd",
        function()
          Core.snacks.picker.diagnostics()
        end,
        desc = "Diagnostics",
      },
      {
        "<leader>sD",
        function()
          Core.snacks.picker.diagnostics_buffer()
        end,
        desc = "Buffer Diagnostics",
      },
      -- {
      --   "<leader>sh",
      --   function()
      --     nvim.snacks.picker.help()
      --   end,
      --   desc = "Help Pages",
      -- },
      {
        "<leader>sH",
        function()
          Core.snacks.picker.highlights()
        end,
        desc = "Highlights",
      },
      {
        "<leader>si",
        function()
          Core.snacks.picker.icons()
        end,
        desc = "Icons",
      },
      {
        "<leader>sj",
        function()
          Core.snacks.picker.jumps()
        end,
        desc = "Jumps",
      },
      {
        "<leader>sk",
        function()
          Core.snacks.picker.keymaps()
        end,
        desc = "Keymaps",
      },
      {
        "<leader>sl",
        function()
          Core.snacks.picker.loclist()
        end,
        desc = "Location List",
      },
      {
        "<leader>sm",
        function()
          Core.snacks.picker.marks()
        end,
        desc = "Marks",
      },
      {
        "<leader>sM",
        function()
          Core.snacks.picker.man()
        end,
        desc = "Man Pages",
      },
      {
        "<leader>sp",
        function()
          Core.snacks.picker.lazy()
        end,
        desc = "Search for Plugin Spec",
      },
      {
        "<leader>sq",
        function()
          Core.snacks.picker.qflist()
        end,
        desc = "Quickfix List",
      },
      {
        "<leader>sR",
        function()
          Core.snacks.picker.resume()
        end,
        desc = "Resume",
      },
      {
        "<leader>su",
        function()
          Core.snacks.picker.undo()
        end,
        desc = "Undo History",
      },
      -- {
      --   "<leader>uC",
      --   function()
      --     nvim.snacks.picker.colorschemes()
      --   end,
      --   desc = "Colorschemes",
      -- },

      -- Other
      {
        "<leader>gg",
        function()
          Core.snacks.lazygit()
        end,
        desc = "Lazygit",
      },
    },

    config = function(_, opts)
      local snacks = require("snacks")
      local redraw_range = snacks.util.redraw_range

      -- wrap this function due to invalid window id error popup
      snacks.util.redraw_range = function(...)
        pcall(redraw_range, ...)
      end

      snacks.setup(opts)
    end,
  },

  -- config: https://github.com/folke/noice.nvim?tab=readme-ov-file#%EF%B8%8F-configuration
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = {
      -- control msgs
      ---@type NoiceRouteConfig[]
      routes = {

        -- show all messages always
        -- https://github.com/folke/noice.nvim/issues/769#issuecomment-2111927208

        -- {
        --   filter = {
        --     any = {
        --       {
        --         cond = function(_)
        --           return true
        --         end,
        --       },
        --     },
        --   },
        -- },
        --
        {
          filter = {
            event = "notify",
            any = {
              { find = "signature help" },
            },
          },
          opts = { skip = true },
        },

        {
          filter = {
            event = "msg_show",
            any = {
              { find = "%d+L, %d+B" },
              { find = "; after #%d+" },
              { find = "; before #%d+" },
              { find = "%d fewer lines" },
              { find = "%d more lines" },
              { find = "%d lines yanked" },
              {
                find = "Error INVALID_SERVER_MESSAGE: nil",
              },
              {
                find = "snacks/util/init.lua:207: Invalid window id",
              },
            },
          },
          opts = { skip = true },
        },

        {
          filter = {
            kind = "progress",
            any = {
              { find = "Searching in files" },
            },
          },
          opts = { skip = true },
        },
      },

      cmdline = {
        enabled = true,
        view = "cmdline_popup",
      },

      -- FIXME: editor view shift when save buffer
      messages = {
        enabled = true,
      },

      popupmenu = {
        enabled = true, -- enables the Noice popupmenu UI
        backend = "nui", -- backend to use to show regular cmdline completions
      },
      -------------------- end --------------------

      lsp = {
        -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true, -- requires hrsh7th/nvim-cmp
        },

        hover = {
          enabled = true,
          silent = true,
          ---@type NoiceViewOptions
          opts = {
            border = "single",

            -- HACK
            size = {
              max_width = select(1, Core.ui.get_doc_window_size()),
              max_height = select(2, Core.ui.get_doc_window_size()),
            },
          },
        },

        signature = {
          enabled = true,
          auto_open = {
            enabled = true,
            trigger = true,
            luasnip = true,
            throttle = 50,
          },
          ---@type NoiceViewOptions
          opts = {
            focusable = false,
            border = "single",

            -- HACK
            size = {
              max_width = select(1, Core.ui.get_doc_window_size()),
              max_height = select(2, Core.ui.get_doc_window_size()),
            },
          },
        },

        progress = {
          enabled = true,
        },
      },

      presets = {
        bottom_search = true, -- use a classic bottom cmdline for search
        command_palette = true, -- position the cmdline and popupmenu together
        long_message_to_split = true, -- long messages will be sent to a split
        inc_rename = false, -- enables an input dialog for inc-rename.nvim
        lsp_doc_border = true, -- add a border to hover docs and signature help
      },

      ---@type NoiceConfigViews
      views = {
        popup = {
          win_options = {
            winhighlight = {
              Normal = "CmpPmenu",
              FloatBorder = "CmpBorder",
            },
          },
        },
        mini = {
          position = {
            row = -3,
            col = "100%",
          },
        },
        ---@type NoiceViewOptions
        popupmenu = {
          -- when auto, then it will be positioned to the cmdline or cursor
          position = "bottom",
        },

        ---@type NoiceViewOptions
        cmdline_popup = {
          position = {
            col = 0.5,
            row = 0.3,
          },
        },

        -- rows must differ by at least 2.5

        ---@type NoiceViewOptions
        cmdline_popupmenu = {
          position = {
            col = 0.5,
            row = 0.56,
          },
        },
      },
    },
    dependencies = {
      -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
      "MunifTanjim/nui.nvim",
      -- OPTIONAL:
      --   `nvim-notify` is only needed, if you want to use the notification view.
      --   If not available, we use `mini` as the fallback
      "rcarriga/nvim-notify",
    },
  },

  {
    "folke/trouble.nvim",
    lazy = false,
    opts = {},
    cmd = "Trouble",
    keys = {
      {
        "<leader>tx",
        "<cmd>Trouble diagnostics toggle<cr>",
        desc = "Diagnostics (Trouble)",
      },
      {
        "<leader>tX",
        "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
        desc = "Buffer Diagnostics (Trouble)",
      },
      {
        "<leader>cs",
        "<cmd>Trouble symbols toggle focus=false<cr>",
        desc = "Symbols (Trouble)",
      },
      {
        "<leader>cL",
        "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
        desc = "LSP Definitions / references / ... (Trouble)",
      },
      {
        "<leader>tL",
        "<cmd>Trouble loclist toggle<cr>",
        desc = "Location List (Trouble)",
      },
      {
        "<leader>tQ",
        "<cmd>Trouble qflist toggle<cr>",
        desc = "Quickfix List (Trouble)",
      },
    },
  },

  -- only work on `keyword:`
  {
    "folke/todo-comments.nvim",
    lazy = false,
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      {
        "<leader>tt",
        "<cmd>TodoTelescope<cr>",
        desc = "Open ToDo Telescope",
      },
    },
    opts = {},
  },
}
