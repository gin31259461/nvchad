local options = {
  events = { "BufWritePost", "BufReadPost", "InsertLeave" },

  linters_by_ft = {
    -- Use the "*" filetype to run linters on all filetypes.
    -- ['*'] = { 'global linter' },
    -- Use the "_" filetype to run linters on filetypes that don't have other linters configured.
    -- ['_'] = { 'fallback linter' },
    -- ["*"] = { "typos" },

    sql = { "sqlfluff" },
    python = { "ruff" },
    docker = { "hadolint" },
    markdown = { "markdownlint-cli2" },
  },

  linters = {
    -- -- Example of using selene only when a selene.toml file is present
    -- selene = {
    --   -- `condition` is another LazyVim extension that allows you to
    --   -- dynamically enable/disable linters based on the context.
    --   condition = function(ctx)
    --     return vim.fs.find({ "selene.toml" }, { path = ctx.filename, upward = true })[1]
    --   end,
    -- },
  },
}

return options
