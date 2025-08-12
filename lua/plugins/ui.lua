---@type LazySpec
return {
  {
    -- config: https://github.com/rachartier/tiny-inline-diagnostic.nvim?tab=readme-ov-file#%EF%B8%8F-setup
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "LspAttach",
    priority = 1000, -- needs to be loaded in first
    opts = {
      preset = "modern",
    },
    config = function(_, opts)
      require("tiny-inline-diagnostic").setup(opts)
    end,
  },
}
