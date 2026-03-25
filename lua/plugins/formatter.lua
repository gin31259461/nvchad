local ft = require("utils.ft")

---@type LazySpec[]
return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePost", "BufReadPost", "InsertLeave" },
    opts = function()
      local opts = require("configs.formatter")

      for _, filetype in ipairs(ft.sql_ft) do
        opts.formatters_by_ft[filetype] = opts.formatters_by_ft[filetype] or {}
        table.insert(opts.formatters_by_ft[filetype], "sqlfluff")
      end

      return opts
    end,
  },
}
