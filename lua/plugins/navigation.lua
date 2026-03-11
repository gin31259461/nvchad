pcall(function()
  dofile(vim.g.base46_cache .. "telescope")
end)

local icons = require("configs").icons

---@type LazySpec[]
return {
  -- https://github.com/stevearc/oil.nvim
  {
    "stevearc/oil.nvim",
    cond = false,
    ---@module 'oil'
    ---@type oil.SetupOpts
    opts = {},
    -- Optional dependencies
    -- dependencies = { { "nvim-mini/mini.icons", opts = {} } },
    dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
    -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
    lazy = false,
    keys = {
      {
        "<C-n>",
        "<cmd>Oil<CR>",
        desc = "Open file explorer",
      },
    },
  },

  {
    "nvim-neo-tree/neo-tree.nvim",
    cond = false,
    cmd = "Neotree",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    keys = {
      {
        "<C-n>",
        "<cmd>Neotree action=show position=left source=last toggle<CR>",
        desc = "Neotree Toggle Window",
      },

      -- {
      --   "<C-n>",
      --   "<cmd>Neotree position=float source=last toggle<CR>",
      --   desc = "Neotree Open Float Window",
      -- },

      {
        "<leader>fe",
        function()
          require("neo-tree.command").execute({ toggle = false, dir = Core.fs.get_root() })
        end,
        desc = "Explorer NeoTree (Root Dir)",
      },
      {
        "<leader>fE",
        function()
          require("neo-tree.command").execute({ toggle = false, dir = vim.uv.cwd() })
        end,
        desc = "Explorer NeoTree (cwd)",
      },

      {
        "<leader>ge",
        function()
          require("neo-tree.command").execute({ source = "git_status", toggle = false })
        end,
        desc = "Git Explorer",
      },
      {
        "<leader>be",
        function()
          require("neo-tree.command").execute({ source = "buffers", toggle = false })
        end,
        desc = "Buffer Explorer",
      },
    },
    deactivate = function()
      vim.cmd([[Neotree close]])
    end,
    init = function()
      -- FIX: use `autocmd` for lazy-loading neo-tree instead of directly requiring it,
      -- because `cwd` is not set up properly.
      vim.api.nvim_create_autocmd("BufEnter", {
        group = vim.api.nvim_create_augroup("Neotree_start_directory", { clear = true }),
        desc = "Start Neo-tree with directory",
        once = true,
        callback = function()
          if package.loaded["neo-tree"] then
            return
          else
            local path = vim.fn.argv(0)
            local stats = type(path) == "string" and vim.uv.fs_stat(path) or nil
            if stats and stats.type == "directory" then
              require("neo-tree")
            end
          end
        end,
      })
    end,
    ---@type neotree.Config
    opts = {
      sources = { "filesystem", "buffers", "git_status" },
      open_files_do_not_replace_types = { "terminal", "Trouble", "trouble", "qf", "Outline" },
      filesystem = {
        hijack_netrw_behavior = "open_current",
        bind_to_cwd = false,
        follow_current_file = { enabled = true },
        use_libuv_file_watcher = true,
      },

      event_handlers = {
        {
          event = "file_added",
          handler = function(state)
            vim.api.nvim_exec_autocmds("User", { pattern = "CreateFile" })
          end,
        },
      },

      window = {
        mappings = {
          -- disable fuzzy finder because it's so slow
          ["/"] = "noop",
          ["l"] = "open",
          ["h"] = "close_node",
          ["<space>"] = "none",
          ["Y"] = function(state)
            ---@diagnostic disable-next-line
            local node = state.tree:get_node()
            local path = node:get_id()
            vim.fn.setreg("+", path, "c")
            vim.notify("Copy Full Path of" .. vim.fn.fnamemodify(path, ":t") .. " to Clipboard")
          end,
          ["O"] = function(state)
            ---@diagnostic disable-next-line
            require("lazy.util").open(state.tree:get_node().path, { system = true })
          end,
          ["P"] = { "toggle_preview", config = { use_float = false } },
        },
      },
      default_component_configs = {
        indent = {
          with_expanders = true, -- if nil and file nesting is enabled, will enable expanders
          expander_collapsed = "",
          expander_expanded = "",
          expander_highlight = "NeoTreeExpander",
        },
        git_status = {
          symbols = {
            unstaged = "󰄱",
            staged = "󰱒",
          },
        },
      },
    },
    config = function(_, opts)
      local function on_move(data)
        Core.snacks.rename.on_rename_file(data.source, data.destination)
      end

      local events = require("neo-tree.events")
      opts.event_handlers = opts.event_handlers or {}
      vim.list_extend(opts.event_handlers, {
        { event = events.FILE_MOVED, handler = on_move },
        { event = events.FILE_RENAMED, handler = on_move },
      })
      require("neo-tree").setup(opts)
      vim.api.nvim_create_autocmd("TermClose", {
        pattern = "*lazygit",
        callback = function()
          if package.loaded["neo-tree.sources.git_status"] then
            require("neo-tree.sources.git_status").refresh()
          end
        end,
      })
    end,
  },

  -- doc: https://github.com/nvim-tree/nvim-tree.lua
  {
    "nvim-tree/nvim-tree.lua",
    cond = true,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    ---@type NvimTreeOpts
    opts = {
      filters = { dotfiles = false },
      disable_netrw = true,
      hijack_cursor = true,
      sync_root_with_cwd = true,
      update_focused_file = {
        enable = true,
        update_root = false,
      },
      view = {
        width = 40,
        preserve_window_proportions = true,
        signcolumn = "no",
      },
      renderer = {
        root_folder_label = false,
        highlight_git = "all",
        highlight_diagnostics = "all",
        indent_markers = { enable = true },
        icons = {
          glyphs = {
            default = icons.fs.default,
            folder = icons.fs.folder,
            git = {
              unstaged = icons.git.unstaged,
              staged = icons.git.staged,
              unmerged = icons.git.unmerged,
            },
          },
        },
      },
      diagnostics = {
        enable = false,
        icons = icons.diagnostics,
      },
      git = {
        enable = true,
        timeout = 5000,
      },
    },
    keys = {
      { "<C-n>", "<cmd>NvimTreeToggle<CR>", desc = "NvimTree Toggle Window" },
      {
        "<leader>e",
        "<cmd>NvimTreeFocus<CR>",
        desc = "NvimTree Focus Window",
      },
    },
    config = function(_, opts)
      require("nvim-tree").setup(opts)
      local api = require("nvim-tree.api")
      local Event = api.events.Event

      api.events.subscribe(Event.FileCreated, function(data)
        vim.api.nvim_exec_autocmds("User", { pattern = "CreateFile" })
      end)
    end,
  },

  -- default keymaps: https://github.com/nvim-telescope/telescope.nvim?tab=readme-ov-file#default-mappings
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    cmd = "Telescope",
    opts = {
      defaults = {
        prompt_prefix = "   ",
        selection_caret = " ",
        entry_prefix = " ",
        sorting_strategy = "ascending",
        wrap_results = false,
        path_display = {
          shorten = { len = 8, exclude = { 1, -1 } },
        },
        layout_config = {
          horizontal = {
            prompt_position = "top",
            preview_width = 0.55,
          },
          width = 0.87,
          height = 0.80,
        },
        mappings = {
          n = {
            ["q"] = require("telescope.actions").close,
            ["<C-j>"] = require("telescope.actions").move_selection_next,
            ["<C-k>"] = require("telescope.actions").move_selection_previous,
          },
          i = {
            ["<C-j>"] = require("telescope.actions").move_selection_next,
            ["<C-k>"] = require("telescope.actions").move_selection_previous,
          },
        },
      },

      -- extensions_list = { "themes", "terms", "noice" },
      extensions = { "noice" },
    },
    config = function(_, opts)
      local telescope = require("telescope")

      for _, v in ipairs(opts.extensions) do
        telescope.load_extension(v)
      end

      telescope.setup(opts)
    end,
  },

  {
    "gin31259461/harpoon",
    -- "ThePrimeagen/harpoon",
    event = "VeryLazy",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
    ---@type HarpoonPartialConfig
    opts = {
      -- https://github.com/ThePrimeagen/harpoon/blob/harpoon2/lua/harpoon/config.lua
      default = {
        -- refer to: https://github.com/ThePrimeagen/harpoon/issues/523#issuecomment-1984926994
        --
        create_list_item = function(config, value)
          value = value
            or Core.fs.make_relative_path(
              vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf()),
              config.get_root_dir()
            )

          local bufnr = vim.fn.bufnr(value, false)
          local pos = { 1, 0 }
          if bufnr ~= -1 then
            pos = vim.api.nvim_win_get_cursor(0)
          end

          return {
            value = value,
            context = {
              row = pos[1],
              col = pos[2],
              short_path = Core.fs.pretty_path(value, { length = Core.ui.harpoon.short_path_length, only_cwd = true }),
            },
          }
        end,

        display = function(list_item)
          local path = list_item.context.short_path or ""
          return Core.ui.harpoon.format_display(path)
        end,
      },
    },
    ---@param opts HarpoonPartialConfig
    config = function(_, opts)
      local harpoon = require("harpoon")

      harpoon:setup(opts)

      -- this will set cursor to current file
      harpoon:extend(Core.ui.harpoon.highlight_current_file())

      vim.keymap.set("n", "<leader>a", function()
        harpoon:list():add()
      end, { desc = "Buffer add into harpoon list" })

      -- Toggle previous & next buffers stored within Harpoon list
      vim.keymap.set("n", "<M-S-p>", function()
        harpoon:list():prev()
      end, { desc = "Toggle previous of harpoon list" })

      vim.keymap.set("n", "<M-S-n>", function()
        harpoon:list():next()
      end, { desc = "Toggle next of harpoon list" })

      -- https://github.com/ThePrimeagen/harpoon/issues/491
      -- currently, telescope is broken on windows so using simple menu

      vim.keymap.set("n", "<C-e>", function()
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end)

      vim.keymap.set("n", "<C-s>", function()
        harpoon.ui:save()
        harpoon.ui:close_menu()
      end)
    end,
  },
}
