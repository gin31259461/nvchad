-- load defaults i.e lua_lsp
require("nvchad.configs.lspconfig").defaults()

local lspconfig = require "lspconfig"
local nvlsp = require "nvchad.configs.lspconfig"
local pkgs = require("configs.packages").lsp

-- lsps with default config
for _, lsp in ipairs(pkgs) do
  lspconfig[lsp].setup {
    on_attach = nvlsp.on_attach,
    on_init = nvlsp.on_init,
    capabilities = nvlsp.capabilities,
  }
end

-- configuring single server
lspconfig.pylsp.setup {
  on_attach = nvlsp.on_attach,
  on_init = nvlsp.on_init,
  capabilities = nvlsp.capabilities,

  settings = {
    pylsp = {
      plugins = {
        pylint = {
          enabled = false,
        },
        pycodestyle = {
          enabled = false,
        },
        pyflakes = {
          enabled = false,
        },
        mccabe = {
          enabled = false,
        },
        autopep8 = {
          enabled = false,
        },
        yapf = {
          enabled = false,
        },
      },
    },
  },
}

lspconfig.denols.setup {
  on_attach = nvlsp.on_attach,
  on_init = nvlsp.on_init,
  capabilities = nvlsp.capabilities,

  root_dir = lspconfig.util.root_pattern("deno.json", "deno.jsonc"),
}

lspconfig.vtsls.setup {
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

  on_attach = nvlsp.on_attach,
  on_init = nvlsp.on_init,
  capabilities = nvlsp.capabilities,
}
