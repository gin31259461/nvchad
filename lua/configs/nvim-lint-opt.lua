local options = {
  events = { "BufWritePost", "BufReadPost", "InsertLeave" },

  linters_by_ft = {
    -- Use the "*" filetype to run linters on all filetypes.
    -- ['*'] = { 'global linter' },
    -- Use the "_" filetype to run linters on filetypes that don't have other linters configured.
    -- ['_'] = { 'fallback linter' },
    -- ["*"] = { "typos" },

    python = { "ruff" },
    docker = { "hadolint" },
    markdown = { "markdownlint-cli2" },

    typescriptreact = { "eslint_d" },
    javascriptreact = { "eslint_d" },
    typescript = { "eslint_d" },
    javascript = { "eslint_d" },
  },

  linters = {
    eslint_d = {
      args = {
        "--no-warn-ignored", -- <-- this is the key argument
        "--stdin",
        "--stdin-filename",
        function()
          return vim.api.nvim_buf_get_name(0)
        end,
      },
    },
  },
}

return options
