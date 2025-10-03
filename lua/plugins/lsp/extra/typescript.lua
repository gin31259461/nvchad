---@type LazySpec[]
return {
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
