local ft = require("utils.ft")

---@type LazySpec[]
return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePost", "BufReadPost", "InsertLeave" },
    opts = function()
      local opts = require("config.formatter")
      local state_mod = require("utils.service_state")
      local svc = require("config.services")

      -- Inject sqlfluff for SQL filetypes before filtering
      if state_mod.is_enabled("formatter", "sqlfluff") then
        for _, filetype in ipairs(ft.sql_ft) do
          opts.formatters_by_ft[filetype] = opts.formatters_by_ft[filetype]
            or {}
          table.insert(opts.formatters_by_ft[filetype], "sqlfluff")
        end
      end

      -- Apply saved priority order then filter disabled formatters
      for filetype, fmts in pairs(opts.formatters_by_ft) do
        local saved = state_mod.get_order("formatter", filetype)
        if saved then
          local reordered = {}
          for _, name in ipairs(saved) do
            if vim.tbl_contains(fmts, name) then
              table.insert(reordered, name)
            end
          end
          for _, name in ipairs(fmts) do
            if not vim.tbl_contains(reordered, name) then
              table.insert(reordered, name)
            end
          end
          fmts = reordered
        end
        opts.formatters_by_ft[filetype] = vim.tbl_filter(function(name)
          -- Unknown formatter names (not in registry) pass through unchanged
          return svc.formatter[name] == nil
            or state_mod.is_enabled("formatter", name)
        end, fmts)
      end

      return opts
    end,
  },
}
