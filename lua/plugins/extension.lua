---@type LazySpec[]
return {
  {
    "obsidian-nvim/obsidian.nvim",
    version = "*", -- use latest release, remove to use latest commit
    lazy = true,
    ft = "markdown",
    ---@module 'obsidian'
    ---@type obsidian.config
    opts = {
      legacy_commands = false, -- this will be removed in the next major release
      workspaces = {
        {
          name = "knowledge base",
          path = vim.fn.expand("~") .. "/OneDrive/Knowledge_Base",
        },
      },
    },
  },
}
