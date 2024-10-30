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
    ["sqlfluff"] = {
      args = { "format", "--dialect=ansi", "-" },
      require_cwd = false,
    },
    ["deno_fmt"] = {
      args = { "fmt", "-" },
    },
  },

  formatters_by_ft = {
    lua = { "stylua" },
    python = { "ruff_fix", "ruff_organize_imports", "ruff_format" },
    sh = { "shfmt" },

    -- web dev
    css = { "deno_fmt" },
    html = { "deno_fmt" },
    typescriptreact = { "deno_fmt", "eslint_d" },
    javascriptreact = { "deno_fmt", "eslint_d" },
    typescript = { "deno_fmt", "eslint_d" },
    javascript = { "deno_fmt", "eslint_d" },
    json = { "deno_fmt" },
    toml = { "taplo" },

    -- markdown
    ["markdown"] = { "deno_fmt", "markdownlint-cli2", "markdown-toc" },
    ["markdown.mdx"] = { "deno_fmt", "markdownlint-cli2", "markdown-toc" },
  },

  format_on_save = {
    -- These options will be passed to conform.format()
    timeout_ms = 2000,
    lsp_fallback = true,
  },
}

return options
