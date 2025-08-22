---@module "lspconfig"

---@class Lsp.Config.Servers
---@field [string] vim.lsp.Config | {keys?: LazyKeysSpec[]}

---@class Lsp.Config.Spec
---@field servers Lsp.Config.Servers
---
---default lsp config for all servers
---@field on_init elem_or_list<fun(client: vim.lsp.Client, init_result: lsp.InitializeResult)>
---@field capabilities lsp.ClientCapabilities
---
---@field setup {[string]: function}
---@field diagnostics vim.diagnostic.Opts
---@field inlay_hints {enabled: boolean, exclude: table}
---@field codelens {enabled: boolean}

local data_path = vim.fs.normalize(vim.fn.stdpath("data"))

---@param opts lsp.ClientCapabilities
local make_client_capabilities = function(opts)
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  return vim.tbl_deep_extend("force", capabilities, opts)
end

---@type Lsp.Config.Spec
return {
  diagnostics = {
    underline = true,
    update_in_insert = false,

    virtual_text = {
      spacing = 4,
      source = "if_many",
      prefix = "●",
      severity = {
        min = vim.diagnostic.severity.WARN,
      },
      -- this will set set the prefix to a function that returns the diagnostics icon based on the severity
      -- this only works on a recent 0.10.0 build. Will be set to "●" when not supported
      -- prefix = "icons",
    },

    -- virtual_text = false,

    severity_sort = true,
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = NvChad.config.icons.diagnostics.Error,
        [vim.diagnostic.severity.WARN] = NvChad.config.icons.diagnostics.Warn,
        [vim.diagnostic.severity.HINT] = NvChad.config.icons.diagnostics.Hint,
        [vim.diagnostic.severity.INFO] = NvChad.config.icons.diagnostics.Info,
      },
    },

    float = { border = "single" },
  },

  -- Enable this to enable the builtin LSP inlay hints on Neovim >= 0.10.0
  -- Be aware that you also will need to properly configure your LSP server to
  -- provide the inlay hints.
  inlay_hints = {
    enabled = true,
    exclude = {}, -- filetypes for which you don't want to enable inlay hints
  },

  -- Enable this to enable the builtin LSP code lenses on Neovim >= 0.10.0
  -- Be aware that you also will need to properly configure your LSP server to
  -- provide the code lenses.
  codelens = {
    enabled = false,
  },

  on_init = function(client, _)
    if client:supports_method("textDocument/semanticTokens") then
      client.server_capabilities.semanticTokensProvider = nil
    end
  end,

  capabilities = make_client_capabilities({
    textDocument = {
      completion = {
        completionItem = {
          documentationFormat = { "markdown", "plaintext" },
          snippetSupport = true,
          preselectSupport = true,
          insertReplaceSupport = true,
          labelDetailsSupport = true,
          deprecatedSupport = true,
          commitCharactersSupport = true,
          tagSupport = { valueSet = { 1 } },
          resolveSupport = {
            properties = {
              "documentation",
              "detail",
              "additionalTextEdits",
            },
          },
        },
      },
    },

    -- workspace = {
    --   fileOperations = {
    --     didCreate = true,
    --     didDelete = true,
    --     didRename = true,
    --     dynamicRegistration = true,
    --   },
    --   didChangeWatchedFiles = {
    --     dynamicRegistration = true,
    --   },
    -- },
    --
  }),

  -- https://www.reddit.com/r/neovim/comments/1guifug/lsp_extreme_lag
  -- flags = {
  --   allow_incremental_sync = false,
  --   debounce_text_changes = 1000,
  -- },

  -- LSP Server Settings
  -- each server config refer to: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md
  servers = {
    lua_ls = {
      settings = {
        Lua = {
          runtime = { version = "LuaJIT" },
          workspace = {
            library = {
              vim.fn.expand("$VIMRUNTIME/lua"),
              "${3rd}/luv/library",
              data_path .. "/lazy/lazy.nvim/lua/lazy",
            },
          },
        },
      },
    },

    -- https://github.com/yioneko/vtsls/blob/main/packages/service/configuration.schema.json
    vtsls = {
      -- explicitly add default filetypes, so that we can extend
      -- them in related extras
      filetypes = {
        "javascript",
        "javascriptreact",
        "javascript.jsx",
        -- "typescript",
        -- "typescriptreact",
        -- "typescript.tsx",
      },
      settings = {
        vtsls = {
          enableMoveToFileCodeAction = true,
          autoUseWorkspaceTsdk = true,
          experimental = {
            maxInlayHintLength = nil,
            completion = {
              entriesLimit = 50,
              enableServerSideFuzzyMatch = true,
            },
          },
        },
        typescript = {
          tsserver = {
            maxTsServerMemory = 4096,
            useSyntaxServer = "auto",
          },
          updateImportsOnFileMove = { enabled = "always" },
          suggest = {
            completeFunctionCalls = true,
          },
          inlayHints = {
            enumMemberValues = { enabled = true },
            functionLikeReturnTypes = { enabled = true },
            parameterNames = { enabled = "literals" },
            parameterTypes = { enabled = true },
            propertyDeclarationTypes = { enabled = true },
            variableTypes = { enabled = false },
          },
        },
      },
      keys = {
        {
          "gD",
          function()
            local params = vim.lsp.util.make_position_params(0, "utf-8")
            NvChad.lsp.execute({
              command = "typescript.goToSourceDefinition",
              arguments = { params.textDocument.uri, params.position },
              open = true,
            })
          end,
          desc = "Goto Source Definition",
        },
        {
          "gR",
          function()
            NvChad.lsp.execute({
              command = "typescript.findAllFileReferences",
              arguments = { vim.uri_from_bufnr(0) },
              open = true,
            })
          end,
          desc = "File References",
        },
        {
          "<leader>co",
          NvChad.lsp.action["source.organizeImports"],
          desc = "Organize Imports",
        },
        {
          "<leader>cM",
          NvChad.lsp.action["source.addMissingImports.ts"],
          desc = "Add missing imports",
        },
        {
          "<leader>cu",
          NvChad.lsp.action["source.removeUnused.ts"],
          desc = "Remove unused imports",
        },
        {
          "<leader>cD",
          NvChad.lsp.action["source.fixAll.ts"],
          desc = "Fix all diagnostics",
        },
        {
          "<leader>cV",
          function()
            NvChad.lsp.execute({ command = "typescript.selectTypeScriptVersion" })
          end,
          desc = "Select TS workspace version",
        },
      },
    },

    ["typescript-tools"] = {
      keys = {
        {
          "<leader>co",
          "<cmd>TSToolsOrganizeImports<cr>",
          desc = "Organize Imports",
        },
      },
    },

    ruff = {
      cmd_env = { RUFF_TRACE = "messages" },
      init_options = {
        settings = {
          logLevel = "error",
        },
      },
      keys = {
        {
          "<leader>co",
          NvChad.lsp.action["source.organizeImports"],
          desc = "Organize Imports",
        },
      },
    },

    -- more lsp setting refer to: https://microsoft.github.io/pyright/#/settings
    pyright = {
      settings = {
        pyright = {
          -- Using Ruff's import organizer
          disableOrganizeImports = true,
          -- disableLanguageServices = true,
        },
        python = {
          analysis = {
            -- default
            autoSearchPaths = true,
            diagnosticMode = "openFilesOnly",

            -- fix completion delay: https://github.com/microsoft/pyright/issues/4878
            -- disable useLibraryCodeForTypes and use extra stubs: https://github.com/microsoft/python-type-stubs
            useLibraryCodeForTypes = false,
            stubPath = data_path .. "/lazy/python-type-stubs/stubs",

            -- use default typeshed so keep following setting commented
            -- https://github.com/python/typeshed
            -- typeshedPaths = {
            --   data_path .. "/lazy/typeshed",
            -- },

            typeCheckingMode = "standard",

            -- Ignore all files for analysis to exclusively use Ruff for linting
            -- ignore = { "*" },
          },
        },
      },
    },

    -- config: https://github.com/python-lsp/python-lsp-server/blob/develop/CONFIGURATION.md
    pylsp = {
      settings = {
        plugins = {
          jedi_completion = {
            fuzzy = true,
          },

          pycodestyle = {
            maxLineLength = 80,
          },

          signature = {
            formatter = "ruff",
            line_length = 100,
          },
        },
      },
    },

    -- config: https://github.com/pappasam/jedi-language-server?tab=readme-ov-file#configuration
    jedi_language_server = {
      init_options = {
        hover = {
          enable = true,
        },
      },
    },

    prismals = {
      keys = {
        {
          "<leader>fp",
          function()
            require("conform").format({ lsp_fallback = true })
            vim.cmd("e!")
          end,
          desc = "prisma format file and force reload",
        },
      },
    },

    powershell_es = {
      bundle_path = "C:/PSES",
      shell = "powershell",
    },

    -- https://www.lazyvim.org/extras/lang/omnisharp
    -- https://github.com/Hoffs/omnisharp-extended-lsp.nvim
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

      -- https://github.com/neovim/neovim/issues/27395
      -- https://github.com/OmniSharp/omnisharp-roslyn/issues/2574
    },
  },

  setup = {
    vtsls = function()
      NvChad.lsp.on_attach(function(client, _)
        client.commands["_typescript.moveToFileRefactoring"] = function(command, _) -- command, ctx
          local arg0, arg1, arg2 = NvChad.unpack(command.arguments)

          ---@type string, string, lsp.Range
          local action, uri, range =
            tostring(arg0), tostring(arg1), {
              start = { line = arg2 and arg2.start_line or 0, character = arg2 and arg2.start_char or 0 },
              ["end"] = { line = arg2 and arg2.end_line or 0, character = arg2 and arg2.end_char or 0 },
            }

          local function move(newf)
            client:request("workspace/executeCommand", {
              command = command.command,
              arguments = { action, uri, range, newf },
            })
          end

          local fname = vim.uri_to_fname(uri)
          client:request("workspace/executeCommand", {
            command = "typescript.tsserverRequest",
            arguments = {
              "getMoveToRefactoringFileSuggestions",
              {
                file = fname,
                startLine = range.start.line + 1,
                startOffset = range.start.character + 1,
                endLine = range["end"].line + 1,
                endOffset = range["end"].character + 1,
              },
            },
          }, function(_, result)
            ---@type string[]
            local files = result.body.files
            table.insert(files, 1, "Enter new path...")
            vim.ui.select(files, {
              prompt = "Select move destination:",
              format_item = function(f)
                return vim.fn.fnamemodify(f, ":~:.")
              end,
            }, function(f)
              if f and f:find("^Enter new path") then
                vim.ui.input({
                  prompt = "Enter move destination:",
                  default = vim.fn.fnamemodify(fname, ":h") .. "/",
                  completion = "file",
                }, function(newf)
                  if type(newf) == "string" then
                    move(newf)
                  end
                end)
              elseif f then
                move(f)
              end
            end)
          end)
        end
      end, "vtsls")
    end,

    ruff = function()
      NvChad.lsp.on_attach(function(client, _)
        -- Disable hover in favor of Pyright
        client.server_capabilities.hoverProvider = false
      end, "ruff")
    end,
  },
}
