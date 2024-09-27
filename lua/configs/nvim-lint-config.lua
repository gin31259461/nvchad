local config = function(_, opts)
  local M = {}
  local lint = require "lint"

  for linter_name, linter in pairs(opts.linters) do
    if type(linter) == "table" and type(lint.linters[linter_name]) == "table" then
      lint.linters[linter_name] = vim.tbl_deep_extend("force", lint.linters[linter_name], linter)
      if type(linter.prepend_args) == "table" then
        lint.linters[linter_name].args = lint.linters[linter_name].args or {}
        vim.list_extend(lint.linters[linter_name].args, linter.prepend_args)
      end
    else
      lint.linters[linter_name] = linter
    end
  end

  lint.linters_by_ft = opts.linters_by_ft

  function M.debounce(ms, fn)
    local timer = vim.uv.new_timer()
    return function(...)
      local argv = { ... }
      if timer ~= nil then
        timer:start(ms, 0, function()
          timer:stop()
          table.unpack = table.unpack or unpack
          vim.schedule_wrap(fn)(table.unpack(argv))
        end)
      end
    end
  end

  function M.lint()
    -- Use nvim-lint's logic first:
    -- * checks if linters exist for the full filetype first
    -- * otherwise will split filetype by "." and add all those linters
    -- * this differs from conform.nvim which only uses the first filetype that has a formatter
    local linter_names = lint._resolve_linter_by_ft(vim.bo.filetype)

    -- Create a copy of the names table to avoid modifying the original.
    linter_names = vim.list_extend({}, linter_names)

    -- Add fallback linters.
    if #linter_names == 0 then
      vim.list_extend(linter_names, lint.linters_by_ft["_"] or {})
    end

    -- Add global linters.
    vim.list_extend(linter_names, lint.linters_by_ft["*"] or {})

    -- Filter out linters that don't exist or don't match the condition.
    local ctx = { filename = vim.api.nvim_buf_get_name(0) }
    ctx.dirname = vim.fn.fnamemodify(ctx.filename, ":h")
    linter_names = vim.tbl_filter(function(linter_name)
      local linter = lint.linters[linter_name]
      if not linter then
        vim.notify("Linter not found: " .. linter_name, vim.log.levels.WARN)
      end
      return linter and not (type(linter) == "table" and linter.condition and not linter.condition(ctx))
    end, linter_names)

    -- Run linters.
    if #linter_names > 0 then
      lint.try_lint(linter_names)
    end
  end

  vim.api.nvim_create_autocmd(opts.events, {
    group = vim.api.nvim_create_augroup("nvim-lint", { clear = true }),
    callback = M.debounce(100, M.lint),
  })
end

return config
