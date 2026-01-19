---@type LazySpec[]
return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    cmd = "Neotree",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    keys = {
      -- {
      --   "<C-n>",
      --   "<cmd>Neotree action=show position=left source=last toggle<CR>",
      --   desc = "Neotree toggle window",
      -- },

      {
        "<C-n>",
        "<cmd>Neotree position=float source=last toggle<CR>",
        desc = "Neotree Open Float Window",
      },

      {
        "<leader>fe",
        function()
          require("neo-tree.command").execute({ toggle = false, dir = NvChad.fs.get_root() })
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
      { "<leader>e", "<leader>fe", desc = "Explorer NeoTree (Root Dir)", remap = true },
      { "<leader>E", "<leader>fE", desc = "Explorer NeoTree (cwd)", remap = true },
      {
        "<leader>ge",
        function()
          require("neo-tree.command").execute({ source = "git_status", toggle = false, position = "float" })
        end,
        desc = "Git Explorer",
      },
      {
        "<leader>be",
        function()
          require("neo-tree.command").execute({ source = "buffers", toggle = false, position = "float" })
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
        NvChad.snacks.rename.on_rename_file(data.source, data.destination)
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
        layout_config = {
          horizontal = {
            prompt_position = "top",
            preview_width = 0.55,
          },
          width = 0.87,
          height = 0.80,
        },
        mappings = {
          n = { ["q"] = require("telescope.actions").close },
        },
      },

      -- extensions_list = { "themes", "terms", "noice" },
      extensions = { "noice" },
    },
    config = function(_, opts)
      -- pcall(function()
      --   dofile(vim.g.base46_cache .. "telescope")
      -- end)

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
            or NvChad.fs.make_relative_path(
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
              short_path = NvChad.fs.pretty_path(
                value,
                { length = NvChad.ui.harpoon.short_path_length, only_cwd = true }
              ),
            },
          }
        end,

        display = function(list_item)
          local path = list_item.context.short_path or ""
          return NvChad.ui.harpoon.format_display(path)
        end,
      },
    },
    ---@param opts HarpoonPartialConfig
    config = function(_, opts)
      local harpoon = require("harpoon")

      harpoon:setup(opts)

      -- this will set cursor to current file
      harpoon:extend(NvChad.ui.harpoon.highlight_current_file())

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
