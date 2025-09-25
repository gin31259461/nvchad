---@type LazySpec
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
    -- config: https://github.com/rachartier/tiny-inline-diagnostic.nvim?tab=readme-ov-file#%EF%B8%8F-setup
    "rachartier/tiny-inline-diagnostic.nvim",
    -- this plugin may has conflict with noice ui, so it's disalbed
    cond = false,
    event = "VeryLazy",
    priority = 1000, -- needs to be loaded in first
    opts = {
      preset = "modern",

      options = {
        -- https://github.com/rachartier/tiny-inline-diagnostic.nvim/issues/40#issuecomment-2331128814
        overwrite_events = { "DiagnosticChanged", "BufEnter" },
      },
    },
    config = function(_, opts)
      require("tiny-inline-diagnostic").setup(opts)
    end,
  },
}
