---@type LazySpec
return {
  {
    "williamboman/mason.nvim",
    -- fix error with typescript-tools
    event = "VeryLazy",
    cmd = { "Mason", "MasonInstall", "MasonUpdate" },
    opts = function()
      return require("nvchad.configs.mason")
    end,
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
        table.insert(opts.formatters_by_ft[ft], "sql_formatter")
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
    config = require("configs.lint-config"),
  },

  {
    "microsoft/python-type-stubs",
  },

  { "Hoffs/omnisharp-extended-lsp.nvim", lazy = true },

  {
    "pmizio/typescript-tools.nvim",
    ft = NvChad.ft.ts,
    dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
    -- https://github.com/pmizio/typescript-tools.nvim?tab=readme-ov-file#%EF%B8%8F-configuration
    opts = {
      ---@param client vim.lsp.Client
      ---@param bufnr number
      on_attach = function(client, bufnr)
        client.server_capabilities.semanticTokensProvider = nil
      end,

      settings = {
        -- https://github.com/microsoft/TypeScript/blob/v5.0.4/src/server/protocol.ts#L3439
        tsserver_file_preferences = {
          includeCompletionsForModuleExports = true,
          quotePreference = "auto",

          -- https://github.com/microsoft/TypeScript/blob/3b45f4db12bbae97d10f62ec0e2d94858252c5ab/src/server/protocol.ts#L3501
          -- includeInlayParameterNameHintsWhenArgumentMatchesName = true,
          -- includeInlayFunctionParameterTypeHints = true,
          -- includeInlayVariableTypeHintsWhenTypeMatchesName = true,
          -- includeInlayPropertyDeclarationTypeHints = true,
          -- includeInlayEnumMemberValueHints = true,

          -- enable following inlay hints will crash the server
          includeInlayParameterNameHints = "none",
          -- includeInlayVariableTypeHints = true,
          -- includeInlayFunctionLikeReturnTypeHints = true,
        },
      },
    },
  },
}
