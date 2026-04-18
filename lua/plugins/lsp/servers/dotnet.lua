-- https://www.lazyvim.org/extras/lang/omnisharp
-- https://github.com/Hoffs/omnisharp-extended-lsp.nvim
-- wiki:            https://github.com/seblyng/roslyn.nvim/wiki
-- diagnostic hack: https://github.com/seblyng/roslyn.nvim/blob/7d8819239c5e2c4a0d8150da1c00fa583f761704/lsp/roslyn.lua#L33

local fs = require("utils.fs")
local os = require("utils.os")

---@type Lsp.Server.Module
return {
  servers = {
    omnisharp = {
      handlers = {
        ["textDocument/definition"] = require("omnisharp_extended").definition_handler,
        ["textDocument/typeDefinition"] = require("omnisharp_extended").type_definition_handler,
        ["textDocument/references"] = require("omnisharp_extended").references_handler,
        ["textDocument/implementation"] = require("omnisharp_extended").implementation_handler,
      },

      keys = {
        {
          "gd",
          function()
            require("omnisharp_extended").telescope_lsp_definitions()
          end,
          desc = "Goto Definition (C#)",
        },
        {
          "gR",
          function()
            require("omnisharp_extended").telescope_lsp_references()
          end,
          desc = "References (C#)",
        },
        {
          "gy",
          function()
            require("omnisharp_extended").telescope_lsp_type_definition()
          end,
          desc = "Goto Type Definition (C#)",
        },
        {
          "gI",
          function()
            require("omnisharp_extended").telescope_lsp_implementation()
          end,
          desc = "Goto Implementation (C#)",
        },
      },

      -- https://github.com/OmniSharp/omnisharp-roslyn/wiki/Configuration-Options
      settings = {
        RoslynExtensionsOptions = {
          enableDecompilationSupport = true,
          enableAnalyzersSupport = true,
          enableImportCompletion = true,
        },
      },
    },

    -- to use this ls, must download roslyn_ls from azure devops and put it in `data/roslyn_ls` folder
    -- refer to: https://github.com/dotnet/roslyn/issues/71474#issuecomment-2177303207
    -- TODO: auto download roslyn_ls and put it in `data/roslyn_ls` folder
    roslyn = {
      filetypes = { "cs" },

      cmd = {
        "dotnet",
        fs.data_path
          .. "/roslyn_ls/content/LanguageServer"
          .. "/"
          .. (os.is_win() and "win" or "linux")
          .. "-x64"
          .. "/Microsoft.CodeAnalysis.LanguageServer.dll",
        "--logLevel", -- this property is required by the server
        "Information",
        "--extensionLogDirectory", -- this property is required by the server
        vim.fs.joinpath(vim.uv.os_tmpdir(), "roslyn_ls/logs"),
        "--stdio",
      },

      on_attach = function(client, bufnr)
        if client:supports_method("textDocument/semanticTokens") then
          client.server_capabilities.semanticTokensProvider = nil
        end

        local roslyn_autorestart_group = vim.api.nvim_create_augroup("RoslynSmartRestart", { clear = true })
        vim.api.nvim_create_autocmd("User", {
          pattern = { "CreateFile" },
          group = roslyn_autorestart_group,
          callback = function(_)
            if client then
              vim.schedule(function()
                vim.notify(
                  "Detect new .cs file, restarting Roslyn to update namespace index",
                  vim.log.levels.INFO,
                  { title = "Roslyn" }
                )
                vim.cmd("lsp restart roslyn")
              end)
            end
          end,
        })
      end,

      keys = {
        {
          "<leader>cx",
          "<cmd>Roslyn restart<CR>",
          desc = "Restart Roslyn Server (When Create or Delete File)",
        },
      },

      settings = {
        ["csharp|inlay_hints"] = {
          csharp_enable_inlay_hints_for_implicit_object_creation = true,
          csharp_enable_inlay_hints_for_implicit_variable_types = true,
          csharp_enable_inlay_hints_for_lambda_parameter_types = true,
          csharp_enable_inlay_hints_for_types = true,
          dotnet_enable_inlay_hints_for_indexer_parameters = true,
          dotnet_enable_inlay_hints_for_literal_parameters = true,
          dotnet_enable_inlay_hints_for_object_creation_parameters = true,
          dotnet_enable_inlay_hints_for_other_parameters = true,
          dotnet_enable_inlay_hints_for_parameters = true,
          dotnet_suppress_inlay_hints_for_parameters_that_differ_only_by_suffix = true,
          dotnet_suppress_inlay_hints_for_parameters_that_match_argument_name = true,
          dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent = true,
        },
        ["csharp|code_lens"] = {
          dotnet_enable_references_code_lens = true,
        },

        ["csharp|background_analysis"] = {
          dotnet_analyzer_diagnostics_scope = "fullSolution",
          dotnet_compiler_diagnostics_scope = "fullSolution",
        },
      },
    },
  },
}
