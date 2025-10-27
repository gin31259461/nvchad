dofile(vim.g.base46_cache .. "mason")

---@type LazySpec[]
local plugins = {
  {
    "williamboman/mason.nvim",
    -- fix error with typescript-tools
    event = "VeryLazy",
    cmd = { "Mason", "MasonInstall", "MasonUpdate" },
    opts = {
      PATH = "skip",

      ui = {
        icons = {
          package_pending = " ",
          package_installed = " ",
          package_uninstalled = " ",
        },
      },

      max_concurrent_installers = 10,

      registries = {
        "github:mason-org/mason-registry",
        "github:Crashdummyy/mason-registry",
      },
    },
  },
  {

    "neovim/nvim-lspconfig",
    lazy = false,
    event = { "BufReadPost", "BufWritePost", "BufNewFile" },
    dependencies = {
      { "williamboman/mason-lspconfig.nvim", config = function() end },
    },

    opts = function()
      return require("plugins.lsp.config")
    end,

    ---@module "plugins.lsp.config"
    ---@param _ LazyPlugin
    ---@param opts Lsp.Config.Spec
    config = function(_, opts)
      -- mapping each lspconfig-opt.servers.[server_name].keys
      NvChad.lsp.on_attach(function(client, buffer)
        require("plugins.lsp.keymaps").on_attach(client, buffer)
      end)

      -- setup servers
      require("plugins.lsp.setup")

      NvChad.lsp.setup()
      NvChad.lsp.on_dynamic_capability(require("plugins.lsp.keymaps").on_attach)

      -- diagnostics signs
      if vim.fn.has("nvim-0.10.0") == 0 then
        if type(opts.diagnostics.signs) ~= "boolean" then
          for severity, icon in pairs(opts.diagnostics.signs.text) do
            local name = vim.diagnostic.severity[severity]:lower():gsub("^%l", string.upper)
            name = "DiagnosticSign" .. name
            vim.fn.sign_define(name, { text = icon, texthl = name, numhl = "" })
          end
        end
      end

      if vim.fn.has("nvim-0.10") == 1 then
        -- inlay hints
        if opts.inlay_hints.enabled then
          NvChad.lsp.on_supports_method("textDocument/inlayHint", function(client, buffer)
            if
              vim.api.nvim_buf_is_valid(buffer)
              and vim.bo[buffer].buftype == ""
              and not vim.tbl_contains(opts.inlay_hints.exclude, vim.bo[buffer].filetype)
            then
              vim.lsp.inlay_hint.enable(true, { bufnr = buffer })
            end
          end)
        end

        -- code lens
        if opts.codelens.enabled and vim.lsp.codelens then
          NvChad.lsp.on_supports_method("textDocument/codeLens", function(client, buffer)
            vim.lsp.codelens.refresh()
            vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
              buffer = buffer,
              callback = vim.lsp.codelens.refresh,
            })
          end)
        end
      end

      if type(opts.diagnostics.virtual_text) == "table" and opts.diagnostics.virtual_text.prefix == "icons" then
        opts.diagnostics.virtual_text.prefix = vim.fn.has("nvim-0.10.0") == 0 and "●"
          or function(diagnostic)
            local icons = NvChad.config.icons.diagnostics
            for d, icon in pairs(icons) do
              if diagnostic.severity == vim.diagnostic.severity[d:upper()] then
                return icon
              end
            end
          end
      end

      vim.diagnostic.config(vim.deepcopy(opts.diagnostics))
    end,
  },

  {
    "stevearc/conform.nvim",
    event = { "BufWritePost", "BufReadPost", "InsertLeave" },
    opts = function()
      local opts = require("configs.conform")

      for _, ft in ipairs(NvChad.ft.sql_ft) do
        opts.formatters_by_ft[ft] = opts.formatters_by_ft[ft] or {}
        table.insert(opts.formatters_by_ft[ft], "sqlfluff")
      end

      return opts
    end,
  },

  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufWritePost", "BufNewFile" },
    opts = function()
      vim.env.ESLINT_D_PPID = vim.fn.getpid()

      local opts = require("configs.lint")

      -- for _, ft in ipairs(NvChad.ft.sql_ft) do
      --   opts.linters_by_ft[ft] = opts.linters_by_ft[ft] or {}
      --   table.insert(opts.linters_by_ft[ft], "sqlfluff")
      -- end

      return opts
    end,
    config = require("plugins.lsp.lint"),
  },
}

local lsp_path = vim.fn.stdpath("config") .. "/lua/plugins/lsp/extra"
local extra = NvChad.fs.scandir(lsp_path, "file")

for _, v in ipairs(extra) do
  local extra_plugins = require("plugins.lsp.extra." .. vim.fn.fnamemodify(v, ":r"))
  plugins = NvChad.merge_plugins_table(plugins, extra_plugins)
end

return plugins
