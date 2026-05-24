---@module "edgy"
---@type LazySpec[]
return {
  {
    "folke/edgy.nvim",
    event = "VeryLazy",
    init = function()
      vim.opt.laststatus = 3
      vim.opt.splitkeep = "screen"
    end,
    opts = {
      close_when_all_hidden = false,

      ---@type (Edgy.View.Opts|string)[]
      right = {
        {
          ft = "trouble",
          size = { width = 0.3 },
          pinned = true,
        },
      },
    },
  },
}
