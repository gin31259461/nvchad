local ft = require("utils.ft")
local str = require("utils.str")

---@type LazySpec[]
return {
  {
    {
      "Orbit-Lua/forge-sql-ui.nvim",
      ft = ft.sql_ft,
      dependencies = {
        "Orbit-Lua/comet.nvim",
        {
          "Orbit-Lua/forge-sql-ls",
          cond = function()
            return vim.fn.executable("go") == 1
          end,
          build = { "go build -o ./bin/forge-sql-ls ./cmd/forge-sql-ls" },
        },
      },
      keys = {
        {
          "<leader>db",
          "<cmd>ForgeSQLUI<CR>",
          desc = "SQL UI",
        },
      },
      opts = {},
    },
  },
}
