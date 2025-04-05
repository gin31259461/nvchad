local sql_ft = require("ft").sql_ft

local plugins = { -- git stuff
  {
    "lewis6991/gitsigns.nvim",
    event = "User FilePost",
    opts = function()
      return require "configs.gitsigns"
    end,
  },

  -- load luasnips + cmp related in insert mode only
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      {
        -- snippet plugin
        "L3MON4D3/LuaSnip",
        dependencies = "rafamadriz/friendly-snippets",
        opts = { history = true, updateevents = "TextChanged,TextChangedI" },
        config = function(_, opts)
          require("luasnip").config.set_config(opts)
          require "nvchad.configs.luasnip"
        end,
      },

      -- autopairing of (){}[] etc
      {
        "windwp/nvim-autopairs",
        opts = {
          fast_wrap = {},
          disable_filetype = { "TelescopePrompt", "vim" },
        },
        config = function(_, opts)
          require("nvim-autopairs").setup(opts)

          -- setup cmp for autopairs
          local cmp_autopairs = require "nvim-autopairs.completion.cmp"
          require("cmp").event:on("confirm_done", cmp_autopairs.on_confirm_done())
        end,
      },

      -- cmp sources plugins
      {
        "saadparwaiz1/cmp_luasnip",
        "hrsh7th/cmp-nvim-lua",
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
      },
    },
    opts = function()
      return require "configs.cmp-opt"
    end,
  },

  {
    "stevearc/conform.nvim",
    event = { "BufWritePost", "BufReadPost", "InsertLeave" },
    opts = function()
      local opts = require "configs.conform-opt"

      for _, ft in ipairs(sql_ft) do
        opts.formatters_by_ft[ft] = opts.formatters_by_ft[ft] or {}
        table.insert(opts.formatters_by_ft[ft], "sql_formatter")
      end

      return opts
    end,
  },

  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPost", "BufWritePost", "BufNewFile" },
    dependencies = {
      "mason.nvim",
      { "williamboman/mason-lspconfig.nvim", config = function() end },
      {
        "yioneko/nvim-vtsls",
        filetypes = {
          "javascript",
          "javascriptreact",
          "javascript.jsx",
          "typescript",
          "typescriptreact",
          "typescript.tsx",
        },
        settings = {
          complete_function_calls = true,
          vtsls = {
            enableMoveToFileCodeAction = true,
            autoUseWorkspaceTsdk = true,
            experimental = {
              maxInlayHintLength = 30,
              completion = {
                enableServerSideFuzzyMatch = true,
              },
            },
          },
          typescript = {
            updateImportsOnFileMove = { enabled = "always" },
            suggest = {
              completeFunctionCalls = true,
            },
            inlayHints = {
              enumMemberValues = { enabled = true },
              functionLikeReturnTypes = { enabled = true },
              parameterNames = { enabled = "literals" },
              parameterTypes = { enabled = true },
              propertyDeclarationTypes = { enabled = true },
              variableTypes = { enabled = false },
            },
          },
        },
        keys = {
          { "<leader>co", "<cmd>VtsExec organize_imports<CR>", desc = "Organize imports" },
          { "<leader>cu", "<cmd>VtsExec remove_unused_imports<CR>", desc = "Remove unused imports" },
          { "<leader>cR", "<cmd>VtsExec file_references<CR>", desc = "File References" },
          { "<leader>cr", "<cmd>VtsExec rename_file<CR>", desc = "Rename file and update all the related paths" },
          { "<leader>cD", "<cmd>VtsExec fix_all<CR>", desc = "Fix all diagnostics" },
          { "<leader>cM", "<cmd>VtsExec add_missing_imports<CR>", desc = "Add missing imports" },
        },
      },
    },
    config = function()
      require "configs.lspconfig"
    end,
  },

  {
    "nvim-tree/nvim-tree.lua",
    cmd = { "NvimTreeToggle", "NvimTreeFocus" },
    opts = require "configs.nvimtree",
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      -- https://github.com/nvim-treesitter/nvim-treesitter?tab=readme-ov-file#modules
      opts.ensure_installed = {
        "html",
        "css",
        "javascript",
        "typescript",
        "tsx",
        "c",
        "cpp",
        "python",
        "bash",
        "markdown",
        "sql",
        "prisma",
      }
    end,
  },

  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    build = "pnpm install && cd app && pnpm install",
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

      local opts = require "configs.nvim-lint-opt"

      -- for _, ft in ipairs(sql_ft) do
      --   opts.linters_by_ft[ft] = opts.linters_by_ft[ft] or {}
      --   table.insert(opts.linters_by_ft[ft], "sqlfluff")
      -- end

      return opts
    end,
    config = require "configs.nvim-lint-config",
  },

  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      file_types = { "markdown", "norg", "rmd", "org" },
      code = {
        sign = false,
        width = "block",
        right_pad = 1,
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
    ft = sql_ft,
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = sql_ft,
        callback = function()
          local cmp = require "cmp"

          local sources = vim.tbl_map(function(source)
            return { name = source.name }
          end, cmp.get_config().sources)

          -- add vim-dadbod-completion source
          table.insert(sources, { name = "vim-dadbod-completion" })

          -- update sources for the current buffer
          cmp.setup.buffer { sources = sources }
        end,
      })
    end,
  },

  {
    "kristijanhusak/vim-dadbod-ui",
    event = { "VeryLazy" },
    cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
    dependencies = "vim-dadbod",
    keys = {
      { "<leader>D", "<cmd>DBUIToggle<CR>", desc = "Toggle DBUI" },
      { "<leader>B", "<cmd>DBUIFindBuffer<CR>", desc = "Add buffer files to DBUI" },
    },
    init = function()
      local data_path = vim.fn.stdpath "data"

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

      vim.filetype.add {
        pattern = { ["*-[Columns|Primary Keys|Indexes|References|Constraints|Foreign Keys|Describe]-[^%.]*"] = "sql" },
      }
    end,
  },

  {
    "folke/edgy.nvim",
    ft = "dbui",
    opts = require "configs.edgy",
  },
}

return plugins
