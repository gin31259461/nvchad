---@type LazySpec[]
return {
  { "Hoffs/omnisharp-extended-lsp.nvim", lazy = true },

  -- https://github.com/seblyng/roslyn.nvim?tab=readme-ov-file#%EF%B8%8F-configuration
  {
    "seblyng/roslyn.nvim",
    ft = { "cs" },
    ---@module 'roslyn.config'
    ---@type RoslynNvimConfig
    opts = {},
  },
}
