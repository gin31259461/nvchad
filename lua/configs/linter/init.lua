-- config for nvim-lint

---@class LinterExtend
---@field condition? boolean

---@alias Linter lint.Linter | LinterExtend | fun(): lint.Linter | LinterExtend

---@module "lint"
---@class Linter.Opts
---@field events LazyEvent
---@field linters_by_ft table
---@field linters Linter

local eslint_d_binary_name = "eslint_d"
local markdownlint_efm = "%f:%l:%c %m,%f:%l %m"
---@type Linter.Opts
return {
  -- events = { "BufWritePost", "BufReadPost", "InsertLeave" },
  events = { "BufWritePost", "BufReadPost", "InsertLeave", "TextChanged" },

  -- available linters: https://github.com/mfussenegger/nvim-lint?tab=readme-ov-file#available-linters
  linters_by_ft = {
    -- Use the "*" filetype to run linters on all filetypes.
    -- ['*'] = { 'global linter' },
    -- Use the "_" filetype to run linters on filetypes that don't have other linters configured.
    -- ['_'] = { 'fallback linter' },
    -- ["*"] = { "typos" },

    -- this has already handle by lspconfig
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

    sqlfluff = {
      command = "sqlfluff",
      args = (function()
        for _, file in ipairs(NvChad.fs.sqlfluff_pattern) do
          local path = NvChad.fs.get_root() .. "/" .. file
          if vim.loop.fs_stat(path) == 0 then
            return { "lint", "--format=json" }
          end
        end

        local config_path = NvChad.fs.config_path .. "/lua/configs/db/template/sqlfluff.cfg"
        return { "lint", "--format=json", "--config", config_path }
      end)(),
    },

    ["markdownlint-cli2"] = {
      cmd = "markdownlint-cli2",
      args = (function()
        local config_path = NvChad.fs.config_path .. "/lua/configs/linter/template/.markdownlint.yaml"
        return { "--config", config_path }
      end)(),
      ignore_exitcode = true,
      stream = "stderr",
      parser = require("lint.parser").from_errorformat(markdownlint_efm, {
        source = "markdownlint",
        severity = vim.diagnostic.severity.WARN,
      }),
    },
  },
}
