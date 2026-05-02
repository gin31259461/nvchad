local ft = require("utils.ft")
local str = require("utils.str")

---@type LazySpec[]
return {
  {
    {
      "Kurren123/mssql.nvim",
      lazy = false,
      opts = {
        -- optional
        keymap_prefix = "<leader>m",
      },
      -- optional
      dependencies = { "folke/which-key.nvim" },
    },
  },
}
