---@class LinterExtend
---@field condition? boolean

---@alias Linter lint.Linter | LinterExtend | fun(): lint.Linter | LinterExtend

---@module "lint"
---@class Linter.Opts
---@field events LazyEvent
---@field linters_by_ft table
---@field linters Linter

local eslint_d_binary_name = "eslint_d"

---@type Linter.Opts
return {
  events = { "BufWritePost", "BufReadPost", "InsertLeave" },

  linters_by_ft = {
    -- Use the "*" filetype to run linters on all filetypes.
    -- ['*'] = { 'global linter' },
    -- Use the "_" filetype to run linters on filetypes that don't have other linters configured.
    -- ['_'] = { 'fallback linter' },
    -- ["*"] = { "typos" },

    -- python = { "ruff" },
    docker = { "hadolint" },
    markdown = { "markdownlint-cli2" },

    typescriptreact = { "eslint_d" },
    javascriptreact = { "eslint_d" },
    typescript = { "eslint_d" },
    javascript = { "eslint_d" },
  },

  linters = {
    eslint_d = require("lint.util").wrap({

      name = "eslint_d",
      stdin = true,
      stream = "stdout",
      ignore_exitcode = true,

      args = {
        "--format",
        "json",
        "--stdin",
        "--stdin-filename",
        function()
          return vim.api.nvim_buf_get_name(0)
        end,
      },

      ---@diagnostic disable-next-line
      cmd = function()
        local local_binary = vim.fn.fnamemodify("./node_modules/.bin/" .. eslint_d_binary_name, ":p")
        return vim.loop.fs_stat(local_binary) and local_binary or eslint_d_binary_name
      end,

      parser = function(output, bufnr)
        local result = require("lint.linters.eslint").parser(output, bufnr)
        for _, d in ipairs(result) do
          d.source = eslint_d_binary_name
        end
        return result
      end,
    }, function(diagnostic)
      if diagnostic.message:find("Error: Could not find config file") then
        return nil
      end
      return diagnostic
    end),
  },
}
