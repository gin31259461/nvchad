pcall(function()
  dofile(vim.g.base46_cache .. "syntax")
  dofile(vim.g.base46_cache .. "treesitter")
end)

---@type LazySpec
return {

  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    opts = {
      ensure_installed = {
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
        "lua",
        "luadoc",
        "comment",
        "c_sharp",
      },

      highlight = {
        enable = true,
      },

      indent = { enable = true },
    },
  },

  {
    -- https://github.com/nvim-treesitter/nvim-treesitter-context
    "nvim-treesitter/nvim-treesitter-context",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = { "BufReadPost", "BufWritePost", "BufNewFile" },
    opts = {
      enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
      multiwindow = false, -- Enable multiwindow support.
      max_lines = 3, -- How many lines the window should span. Values <= 0 mean no limit.
      min_window_height = 0, -- Minimum editor window height to enable context. Values <= 0 mean no limit.
      line_numbers = true,
      multiline_threshold = 20, -- Maximum number of lines to show for a single context
      trim_scope = "outer", -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
      mode = "cursor", -- Line used to calculate context. Choices: 'cursor', 'topline'
      -- Separator between context and content. Should be a single character string, like '-'.
      -- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
      separator = nil,
      zindex = 20, -- The Z-index of the context window
      on_attach = nil, -- (fun(buf: integer): boolean) return false to disable attaching
    },
  },

  {
    "hrsh7th/nvim-cmp",
    version = false,
    event = "InsertEnter",
    dependencies = {
      {
        -- snippet plugin
        "L3MON4D3/LuaSnip",
        dependencies = "rafamadriz/friendly-snippets",
        opts = { history = true, updateevents = "TextChanged,TextChangedI" },
        config = function(_, opts)
          require("luasnip").config.set_config(opts)
          require("nvchad.configs.luasnip")
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
          local cmp_autopairs = require("nvim-autopairs.completion.cmp")
          require("cmp").event:on("confirm_done", cmp_autopairs.on_confirm_done())
        end,
      },

      -- cmp sources plugins
      {
        "saadparwaiz1/cmp_luasnip",
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
      },

      -- improve lua annotations and cmp
      {
        "folke/lazydev.nvim",
        ft = "lua",

        -- https://github.com/DrKJeff16/wezterm-types
        dependencies = {
          { "justinsgithub/wezterm-types", lazy = true },
        },

        opts = {
          library = {
            -- Load luvit types when the `vim.uv` word is found
            -- { path = "${3rd}/luv/library", words = { "vim%.uv" } },

            -- Load the ui types when the `ui` module is required
            { path = "ui/nvchad_types", mods = { "ui" } },

            { path = "lazy.nvim", mods = { "lazy" } },
            { path = "snacks.nvim", words = { "snacks", "snacks.nvim" } },
            { path = "noice.nvim", words = { "noice", "noice.nvim" } },
            { path = "wezterm-types", mods = { "wezterm", "module.wezterm" } },
          },
        },
      },
    },

    opts = function()
      return require("configs.cmp-opt")
    end,

    main = "utils.cmp",
  },
}
