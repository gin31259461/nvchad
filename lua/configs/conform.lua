local options = {
  formatters = {
    ["markdown-toc"] = {
      condition = function(_, ctx)
        for _, line in ipairs(vim.api.nvim_buf_get_lines(ctx.buf, 0, -1, false)) do
          if line:find "<!%-%- toc %-%->" then
            return true
          end
        end
      end,
    },
    ["markdownlint-cli2"] = {
      condition = function(_, ctx)
        local diag = vim.tbl_filter(function(d)
          return d.source == "markdownlint"
        end, vim.diagnostic.get(ctx.buf))
        return #diag > 0
      end,
    },
  },

  formatters_by_ft = {
    lua = { "stylua" },
    python = { "ruff_fix", "ruff_organize_imports", "ruff_format" },
    sh = { "shfmt" },
    sql = { "sqlfluff" },

    -- web dev
    css = { "prettier" },
    html = { "prettier" },
    typescript = { "prettier" },
    javascript = { "prettier" },

    -- markdown
    ["markdown"] = { "prettier", "markdownlint-cli2", "markdown-toc" },
    ["markdown.mdx"] = { "prettier", "markdownlint-cli2", "markdown-toc" },
  },

  format_on_save = {
    -- These options will be passed to conform.format()
    timeout_ms = 500,
    lsp_fallback = true,
  },
}

return options
