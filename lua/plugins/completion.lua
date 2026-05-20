---@type LazySpec[]
return {
  {
    "hrsh7th/nvim-cmp",
    lazy = false,
    event = "InsertEnter",
    dependencies = {
      {
        "L3MON4D3/LuaSnip",
        dependencies = "rafamadriz/friendly-snippets",
        build = { "make install_jsregexp" },
        opts = { history = true, updateevents = "TextChanged,TextChangedI" },
        config = function(_, opts)
          require("luasnip").config.set_config(opts)
          require("nvchad.configs.luasnip")
        end,
      },

      {
        "windwp/nvim-autopairs",
        opts = {
          fast_wrap = {},
          disable_filetype = { "TelescopePrompt", "vim" },
        },
        config = function(_, opts)
          require("nvim-autopairs").setup(opts)
          local cmp_autopairs = require("nvim-autopairs.completion.cmp")
          require("cmp").event:on(
            "confirm_done",
            cmp_autopairs.on_confirm_done()
          )
        end,
      },

      {
        "saadparwaiz1/cmp_luasnip",
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
      },

      {
        "folke/lazydev.nvim",
        ft = "lua",

        -- https://github.com/DrKJeff16/wezterm-types
        dependencies = {
          { "justinsgithub/wezterm-types", lazy = true },
        },

        opts = {
          library = {
            { path = "nvchad-ui/nvchad_types", mods = { "ui" } },
            { path = "snacks.nvim", words = { "snacks", "snacks.nvim" } },
            { path = "noice.nvim", words = { "noice", "noice.nvim" } },
            { path = "comet.nvim", words = { "Comet", "comet.nvim" } },
            { path = "nvim-cmp/lua/cmp/types", words = { "nvim%-cmp" } },
            { path = "wezterm-types", mods = { "wezterm", "module.wezterm" } },
          },
        },
      },
    },

    opts = function()
      return require("config.cmp")
    end,

    main = "utils.cmp",
  },
}
