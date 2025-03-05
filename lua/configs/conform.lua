local options = {
  default_format_opts = {
    timeout_ms = 5000,
    async = true, -- not recommended to change
    quiet = false, -- not recommended to change
    lsp_format = "fallback", -- not recommended to change
  },

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
      args = { "format", "--dialect", "ansi", "-" },
      -- require_cwd = false,
    },
    ["sql_formatter"] = {
      args = function()
        local current_dir = vim.fn.expand "%:h"
        local current_config_path = string.format("%s/.sql-formatter.json", current_dir)

        return { "--config", current_config_path }
      end,
    },
    ["deno_fmt"] = {
      args = function()
        local current_filetype = vim.bo.filetype

        if current_filetype == "json" then
          return { "fmt", "--ext=json", "-" }
        else
          return { "fmt", "-" }
        end
      end,
    },
    ["prisma_fmt"] = {
      command = function()
        local shell = require "shell"

        if shell.is_windows() then
          return vim.fn.getcwd() .. "/node_modules/.bin/prisma.CMD"
        end
      end,
      condition = function(_, ctx)
        return vim.bo[ctx.buf].filetype == "prisma"
      end,
      args = { "format" },
      stdin = false,
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
    prisma = { "prisma_fmt" },

    -- markdown
    ["markdown"] = { "deno_fmt", "markdownlint-cli2", "markdown-toc" },
    ["markdown.mdx"] = { "deno_fmt", "markdownlint-cli2", "markdown-toc" },
  },

  format_on_save = false,

  -- format_on_save = function()
  --   if vim.bo.filetype == "prisma" then
  --     return
  --   end
  --
  --   -- These options will be passed to conform.format()
  --   return { timeout_ms = 2000, lsp_fallback = true }
  -- end,
}

return options
