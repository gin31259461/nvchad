local lsp = require("utils.lsp")
local ft = require("utils.ft")
local utils = require("utils")

-- https://github.com/yioneko/vtsls/blob/main/packages/service/configuration.schema.json
return {
  servers = {
    vtsls = {
      filetypes = ft.js,
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
            lsp.execute({
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
            lsp.execute({
              command = "typescript.findAllFileReferences",
              arguments = { vim.uri_from_bufnr(0) },
              open = true,
            })
          end,
          desc = "File References",
        },
        { "<leader>co", lsp.action["source.organizeImports"],        desc = "Organize Imports" },
        { "<leader>cM", lsp.action["source.addMissingImports.ts"],   desc = "Add missing imports" },
        { "<leader>cu", lsp.action["source.removeUnused.ts"],        desc = "Remove unused imports" },
        { "<leader>cD", lsp.action["source.fixAll.ts"],              desc = "Fix all diagnostics" },
        {
          "<leader>cV",
          function()
            lsp.execute({ command = "typescript.selectTypeScriptVersion" })
          end,
          desc = "Select TS workspace version",
        },
      },
    },

    ["typescript-tools"] = {
      keys = {
        { "<leader>co", "<cmd>TSToolsOrganizeImports<cr>", desc = "Organize Imports" },
      },
    },
  },

  setup = {
    vtsls = function()
      lsp.on_attach(function(client, _)
        client.commands["_typescript.moveToFileRefactoring"] = function(command, _)
          local arg0, arg1, arg2 = utils.unpack(command.arguments)

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
  },
}
