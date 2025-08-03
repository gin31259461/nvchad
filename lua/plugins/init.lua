---@type LazySpec
return {
  -- git stuff
  {
    "lewis6991/gitsigns.nvim",
    event = "User FilePost",
    opts = function()
      return require("configs.gitsigns")
    end,
  },

  {
    "stevearc/conform.nvim",
    event = { "BufWritePost", "BufReadPost", "InsertLeave" },
    opts = function()
      local opts = require("configs.conform-opt")

      for _, ft in ipairs(nvim.ft.sql_ft) do
        opts.formatters_by_ft[ft] = opts.formatters_by_ft[ft] or {}
        table.insert(opts.formatters_by_ft[ft], "sql_formatter")
      end

      return opts
    end,
  },

  -- {
  --   "nvim-tree/nvim-tree.lua",
  --   cmd = { "NvimTreeToggle", "NvimTreeFocus" },
  --   opts = function()
  --     return require "configs.nvimtree"
  --   end,
  -- },

  {
    "nvim-neo-tree/neo-tree.nvim",
    cmd = "Neotree",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
      "MunifTanjim/nui.nvim",
    },
    keys = {
      -- {
      --   "<leader>fE",
      --   function()
      --     require("neo-tree.command").execute { toggle = true, position = "right", dir = nvim.root() }
      --   end,
      --   desc = "Explorer NeoTree (Root Dir)",
      -- },
      {
        "<leader>fe",
        function()
          require("neo-tree.command").execute({ toggle = true, position = "right", dir = vim.uv.cwd() })
        end,
        desc = "Explorer NeoTree (cwd)",
      },
      -- { "<leader>E", "<leader>fE", desc = "Explorer NeoTree (Root Dir)", remap = true },
      { "<leader>e", "<leader>fe", desc = "Explorer NeoTree (cwd)", remap = true },
      {
        "<leader>ge",
        function()
          require("neo-tree.command").execute({ source = "git_status", toggle = true, position = "right" })
        end,
        desc = "Git Explorer",
      },
      {
        "<leader>be",
        function()
          require("neo-tree.command").execute({ source = "buffers", toggle = true, position = "right" })
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
            local stats = vim.uv.fs_stat(vim.fn.argv(0))
            if stats and stats.type == "directory" then
              require("neo-tree")
            end
          end
        end,
      })
    end,
    opts = {
      sources = { "filesystem", "buffers", "git_status" },
      open_files_do_not_replace_types = { "terminal", "Trouble", "trouble", "qf", "Outline" },
      filesystem = {
        bind_to_cwd = false,
        follow_current_file = { enabled = true },
        use_libuv_file_watcher = true,
      },
      window = {
        mappings = {
          ["l"] = "open",
          ["h"] = "close_node",
          ["<space>"] = "none",
          ["Y"] = {
            function(state)
              local node = state.tree:get_node()
              local path = node:get_id()
              vim.fn.setreg("+", path, "c")
            end,
            desc = "Copy Path to Clipboard",
          },
          ["O"] = {
            function(state)
              require("lazy.util").open(state.tree:get_node().path, { system = true })
            end,
            desc = "Open with System Application",
          },
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
        nvim.snacks.rename.on_rename_file(data.source, data.destination)
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

  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    opts = function()
      return require("configs.treesitter")
    end,
  },

  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    build = "yarn && cd app && yarn",
    init = function()
      vim.g.mkdp_filetypes = { "markdown" }
    end,
    ft = { "markdown" },
  },

  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    keys = { "<leader>", "<c-r>", "<c-w>", '"', "'", "`", "c", "v", "g" },
    cmd = "WhichKey",
    config = function(_, opts)
      dofile(vim.g.base46_cache .. "whichkey")
      require("which-key").setup(opts)
    end,
  },

  {
    "mfussenegger/nvim-lint",
    event = { "BufWritePost", "BufReadPost", "InsertLeave" },
    opts = function()
      vim.env.ESLINT_D_PPID = vim.fn.getpid()

      local opts = require("configs.nvim-lint-opt")

      -- for _, ft in ipairs(sql_ft) do
      --   opts.linters_by_ft[ft] = opts.linters_by_ft[ft] or {}
      --   table.insert(opts.linters_by_ft[ft], "sqlfluff")
      -- end

      return opts
    end,
    config = require("configs.nvim-lint-config"),
  },

  -- config refer to: https://github.com/MeanderingProgrammer/render-markdown.nvim?tab=readme-ov-file#setup
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      file_types = { "markdown", "norg", "rmd", "org" },
      code = {
        sign = false,
        width = "full",
        right_pad = 1,
        disable_background = true,
      },
      heading = {
        sign = false,
        icons = {},
      },
    },
    ft = { "markdown", "norg", "rmd", "org" },
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" }, -- if you prefer nvim-web-devicons
    -- dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.nvim" }, -- if you use the mini.nvim suite
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' }, -- if you use standalone mini plugins
  },

  {
    "tpope/vim-dadbod",
    cmd = "DB",
  },

  {
    "kristijanhusak/vim-dadbod-completion",
    dependencies = "vim-dadbod",
    ft = nvim.ft.sql_ft,
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = nvim.ft.sql_ft,
        callback = function()
          local cmp = require("cmp")

          local sources = vim.tbl_map(function(source)
            return { name = source.name }
          end, cmp.get_config().sources)

          -- add vim-dadbod-completion source
          table.insert(sources, { name = "vim-dadbod-completion" })

          -- update sources for the current buffer
          cmp.setup.buffer({ sources = sources })
        end,
      })
    end,
  },

  {
    "kristijanhusak/vim-dadbod-ui",
    event = { "VeryLazy" },
    ft = nvim.ft.sql_ft,
    cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
    dependencies = "vim-dadbod",
    keys = {
      { "<leader>D", "<cmd>DBUIToggle<CR>", desc = "Toggle DBUI" },
      { "<leader>B", "<cmd>DBUIFindBuffer<CR>", desc = "Add buffer files to DBUI" },
    },
    init = function()
      local data_path = vim.fn.stdpath("data")

      vim.g.db_ui_auto_execute_table_helpers = 1
      vim.g.db_ui_save_location = data_path .. "/dadbod_ui"
      vim.g.db_ui_show_database_icon = true
      vim.g.db_ui_tmp_query_location = data_path .. "/dadbod_ui/tmp"
      vim.g.db_ui_use_nerd_fonts = true
      vim.g.db_ui_use_nvim_notify = true

      -- NOTE: The default behavior of auto-execution of queries on save is disabled
      -- this is useful when you have a big query that you don't want to run every time
      -- you save the file running those queries can crash neovim to run use the
      -- default keymap: <leader>S
      vim.g.db_ui_execute_on_save = false

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "dbout",
        callback = function()
          vim.wo.foldenable = false
        end,
      })

      vim.filetype.add({
        pattern = { ["*-[Columns|Primary Keys|Indexes|References|Constraints|Foreign Keys|Describe]-[^%.]*"] = "sql" },
      })
    end,
  },

  {
    "folke/edgy.nvim",
    ft = "dbui",
    opts = require("configs.edgy"),
  },

  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    cmd = "Telescope",
    opts = function()
      local opts = require("nvchad.configs.telescope")
      table.insert(opts.extensions_list, "noice")
      return opts
    end,
  },
}
