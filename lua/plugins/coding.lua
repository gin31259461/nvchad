pcall(function()
  dofile(vim.g.base46_cache .. "syntax")
  dofile(vim.g.base46_cache .. "treesitter")
end)

---@type LazySpec[]
return {
  {
    -- https://github.com/nvim-treesitter/nvim-treesitter/issues/8350
    -- [Lua]: Invalid node type "substitute"
    -- Solution: delete nvim-treesitter manually and reinstall
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    branch = "main",
    event = { "BufReadPost", "BufNewFile" },
    cmd = { "TSInstall", "TSBufEnable", "TSBufDisable", "TSModuleInfo" },
    build = { ":TSUpdate | TSInstallAll", "npm install -g tree-sitter-cli" },

    ---@module "nvim-treesitter"
    ---@type TSConfig
    ---@diagnostic disable-next-line
    opts = {
      install_dir = vim.fn.stdpath("data") .. "/site",
      ensure_installed = {
        "lua",
        "luadoc",
        "printf",
        "vim",
        "vimdoc",
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
        "comment",
        "c_sharp",
        "xml",
      },
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

  -- https://github.com/nvim-treesitter/nvim-treesitter-textobjects/tree/main
  -- {
  --   "nvim-treesitter/nvim-treesitter-textobjects",
  --   dependencies = { "nvim-treesitter/nvim-treesitter" },
  --   branch = "main",
  --   opts = {
  --     move = {
  --       -- whether to set jumps in the jumplist
  --       set_jumps = true,
  --     },
  --   },
  --   config = function(_, opts)
  --     require("nvim-treesitter-textobjects").setup(opts)
  --
  --     local mv = require("nvim-treesitter-textobjects.move")
  --     vim.keymap.set({ "n", "x", "o" }, "]m", function()
  --       mv.goto_next_start("@function.outer", "textobjects")
  --     end)
  --     vim.keymap.set({ "n", "x", "o" }, "]M", function()
  --       mv.goto_next_end("@function.outer", "textobjects")
  --     end)
  --   end,
  -- },

  -- https://www.reddit.com/r/neovim/comments/1agjong/html_tags/
  -- https://github.com/andymass/vim-matchup?tab=readme-ov-file#installation
  {
    "andymass/vim-matchup",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    init = function()
      -- modify your configuration vars here
      vim.g.matchup_treesitter_stopline = 500
      vim.g.matchup_matchparen_offscreen = { method = "popup", fullwidth = 1, border = 0 }

      -- or call the setup function provided as a helper. It defines the
      -- configuration vars for you
      require("match-up").setup({
        ---@diagnostic disable-next-line
        treesitter = {
          stopline = 500,
        },
      })
    end,
    -- or use the `opts` mechanism built into `lazy.nvim`. It calls
    -- `require('match-up').setup` under the hood
    ---@type matchup.Config
    ---@diagnostic disable-next-line
    opts = {
      ---@diagnostic disable-next-line
      treesitter = {
        stopline = 500,
      },
    },
  },
  -- https://github.com/windwp/nvim-ts-autotag
  {
    "windwp/nvim-ts-autotag",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = { "BufReadPre", "BufNewFile" },

    ---@type nvim-ts-autotag.PluginSetup
    opts = {

      opts = {
        -- Defaults
        enable_close = true, -- Auto close tags
        enable_rename = true, -- Auto rename pairs of tags
        enable_close_on_slash = false, -- Auto close on trailing </
      },

      aliases = {
        ["pubxml"] = "xml",
      },
    },

    config = function(_, opts)
      require("nvim-ts-autotag").setup(opts)
    end,
  },

  {
    "hrsh7th/nvim-cmp",
    -- version = false,
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
            { path = "nvchad-ui/nvchad_types", mods = { "ui" } },

            { path = "snacks.nvim", words = { "snacks", "snacks.nvim" } },
            { path = "noice.nvim", words = { "noice", "noice.nvim" } },
            { path = "wezterm-types", mods = { "wezterm", "module.wezterm" } },
          },
        },
      },
    },

    opts = function()
      return require("configs.cmp")
    end,

    main = "utils.cmp",
  },

  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = "User FilePost",
    ---@type ibl.config
    opts = {
      indent = { char = "│", highlight = "IblChar" },
      scope = { char = "│", highlight = "IblScopeChar" },
    },
    config = function(_, opts)
      dofile(vim.g.base46_cache .. "blankline")

      local hooks = require("ibl.hooks")
      hooks.register(hooks.type.WHITESPACE, hooks.builtin.hide_first_space_indent_level)
      require("ibl").setup(opts)

      dofile(vim.g.base46_cache .. "blankline")
    end,
  },
}
