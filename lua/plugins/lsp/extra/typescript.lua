---@type LazySpec[]
return {
  {
    "pmizio/typescript-tools.nvim",
    ft = Core.ft.ts,
    dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
    -- https://github.com/pmizio/typescript-tools.nvim?tab=readme-ov-file#%EF%B8%8F-configuration
    opts = {
      ---@param client vim.lsp.Client
      ---@param bufnr number
      on_attach = function(client, bufnr)
        client.server_capabilities.semanticTokensProvider = nil
      end,

      -- ---@type vim.lsp.Config
      -- config = {
      --   handlers = {
      --     -- HACK: drop duplicated diagnostic message
      --     -- https://neovim.io/doc/user/lsp.html#lsp-handler
      --     ---@type lsp.Handler
      --     ["textDocument/publishDiagnostics"] = function(err, res, ctx)
      --       local filtered = {}
      --       res.diagnostics = NvChad.table.unique_by_key(res.diagnostics, "message")
      --       for _, diag in ipairs(res.diagnostics) do
      --         if diag.source == "tsserver" then
      --           table.insert(filtered, diag)
      --         end
      --       end
      --
      --       res.diagnostics = filtered
      --       vim.lsp.diagnostic.on_publish_diagnostics(err, res, ctx)
      --     end,
      --   },
      -- },

      handlers = {
        -- HACK: drop duplicated diagnostic message
        -- https://neovim.io/doc/user/lsp.html#lsp-handler
        ---@type lsp.Handler
        ["textDocument/publishDiagnostics"] = function(err, res, ctx)
          local filtered = {}
          res.diagnostics = Core.table.unique_by_key(res.diagnostics, "message")
          for _, diag in ipairs(res.diagnostics) do
            if diag.source == "tsserver" then
              table.insert(filtered, diag)
            end
          end

          res.diagnostics = filtered
          vim.lsp.diagnostic.on_publish_diagnostics(err, res, ctx)
        end,
      },

      settings = {
        separate_diagnostic_server = true,
        code_lens = "off",

        -- https://github.com/microsoft/TypeScript/blob/v5.0.4/src/server/protocol.ts#L3439
        tsserver_file_preferences = {
          includeCompletionsForModuleExports = true,
          quotePreference = "auto",

          -- https://github.com/microsoft/TypeScript/blob/3b45f4db12bbae97d10f62ec0e2d94858252c5ab/src/server/protocol.ts#L3501
          includeInlayParameterNameHintsWhenArgumentMatchesName = true,
          includeInlayFunctionParameterTypeHints = true,
          includeInlayVariableTypeHintsWhenTypeMatchesName = true,
          includeInlayPropertyDeclarationTypeHints = true,
          includeInlayEnumMemberValueHints = true,

          -- enable following inlay hints may crash the server
          -- includeInlayParameterNameHints = "none",
          includeInlayParameterNameHints = "literals",
          includeInlayVariableTypeHints = true,
          includeInlayFunctionLikeReturnTypeHints = true,
        },
      },
    },
  },
}
