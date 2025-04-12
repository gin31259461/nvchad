local options = {
  -- options for vim.diagnostic.config()
  ---@type vim.diagnostic.Opts
  diagnostics = {
    underline = true,
    update_in_insert = false,
    virtual_text = {
      spacing = 4,
      source = "if_many",
      prefix = "●",
      -- this will set set the prefix to a function that returns the diagnostics icon based on the severity
      -- this only works on a recent 0.10.0 build. Will be set to "●" when not supported
      -- prefix = "icons",
    },
    severity_sort = true,
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = nvim.configs.icons.diagnostics.Error,
        [vim.diagnostic.severity.WARN] = nvim.configs.icons.diagnostics.Warn,
        [vim.diagnostic.severity.HINT] = nvim.configs.icons.diagnostics.Hint,
        [vim.diagnostic.severity.INFO] = nvim.configs.icons.diagnostics.Info,
      },
    },
  },
  -- Enable this to enable the builtin LSP inlay hints on Neovim >= 0.10.0
  -- Be aware that you also will need to properly configure your LSP server to
  -- provide the inlay hints.
  inlay_hints = {
    enabled = true,
    exclude = { "vue" }, -- filetypes for which you don't want to enable inlay hints
  },
  -- Enable this to enable the builtin LSP code lenses on Neovim >= 0.10.0
  -- Be aware that you also will need to properly configure your LSP server to
  -- provide the code lenses.
  codelens = {
    enabled = false,
  },
  -- add any global capabilities here
  capabilities = {
    workspace = {
      fileOperations = {
        didRename = true,
        willRename = true,
      },
    },
  },
  -- options for vim.lsp.buf.format
  -- `bufnr` and `filter` is handled by the LazyVim formatter,
  -- but can be also overridden when specified
  format = {
    formatting_options = nil,
    timeout_ms = nil,
  },

  -- LSP Server Settings
  servers = {
    vtsls = {
      -- explicitly add default filetypes, so that we can extend
      -- them in related extras
      filetypes = {
        "javascript",
        "javascriptreact",
        "javascript.jsx",
        "typescript",
        "typescriptreact",
        "typescript.tsx",
      },
      settings = {
        complete_function_calls = true,
        vtsls = {
          enableMoveToFileCodeAction = true,
          autoUseWorkspaceTsdk = true,
          experimental = {
            maxInlayHintLength = 30,
            completion = {
              enableServerSideFuzzyMatch = true,
            },
          },
        },
        typescript = {
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
            local params = vim.lsp.util.make_position_params()
            nvim.lsp.execute {
              command = "typescript.goToSourceDefinition",
              arguments = { params.textDocument.uri, params.position },
              open = true,
            }
          end,
          desc = "Goto Source Definition",
        },
        {
          "gR",
          function()
            nvim.lsp.execute {
              command = "typescript.findAllFileReferences",
              arguments = { vim.uri_from_bufnr(0) },
              open = true,
            }
          end,
          desc = "File References",
        },
        {
          "leader>co",
          nvim.lsp.action["source.organizeImports"],
          desc = "Organize Imports",
        },
        {
          "<leader>cM",
          nvim.lsp.action["source.addMissingImports.ts"],
          desc = "Add missing imports",
        },
        {
          "<leader>cu",
          nvim.lsp.action["source.removeUnused.ts"],
          desc = "Remove unused imports",
        },
        {
          "<leader>cD",
          nvim.lsp.action["source.fixAll.ts"],
          desc = "Fix all diagnostics",
        },
        {
          "<leader>cV",
          function()
            nvim.lsp.execute { command = "typescript.selectTypeScriptVersion" }
          end,
          desc = "Select TS workspace version",
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
          nvim.lsp.action["source.organizeImports"],
          desc = "Organize Imports",
        },
        {
          "<leader>co",
          nvim.lsp.action["source.organizeImports"],
          desc = "Organize Imports",
        },
      },
    },

    prismals = {
      keys = {
        {
          "<leader>fe",
          function()
            require("conform").format { lsp_fallback = true }
            vim.cmd "e!"
          end,
          desc = "prisma format file and force reload",
        },
      },
    },
  },

  setup = {
    vtsls = function(_, opts)
      nvim.lsp.on_attach(function(client, _) -- client, buffer
        client.commands["_typescript.moveToFileRefactoring"] = function(command, _) -- command, ctx
          local arg0, arg1, arg2 = nvim.utils.unpack(command.arguments)

          ---@type string, string, lsp.Range
          local action, uri, range =
            tostring(arg0), tostring(arg1), {
              start = { line = arg2 and arg2.start_line or 0, character = arg2 and arg2.start_char or 0 },
              ["end"] = { line = arg2 and arg2.end_line or 0, character = arg2 and arg2.end_char or 0 },
            }

          local function move(newf)
            client.request("workspace/executeCommand", {
              command = command.command,
              arguments = { action, uri, range, newf },
            })
          end

          local fname = vim.uri_to_fname(uri)
          client.request("workspace/executeCommand", {
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
              if f and f:find "^Enter new path" then
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

      -- copy typescript settings to javascript
      opts.settings.javascript =
        vim.tbl_deep_extend("force", {}, opts.settings.typescript, opts.settings.javascript or {})
    end,

    ruff = function()
      nvim.lsp.on_attach(function(client, _)
        -- Disable hover in favor of Pyright
        client.server_capabilities.hoverProvider = false
      end, "ruff")
    end,
  },
}

return options
