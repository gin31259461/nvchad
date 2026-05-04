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
---@field disable_default_settings {[string]: table}
---@field setup {[string]: fun()}
---@field diagnostics vim.diagnostic.Opts
---@field inlay_hints {enabled: boolean, exclude: table}
---@field codelens {enabled: boolean, autocmd: boolean}

---@class Lsp.Server.Module
---@field servers? Lsp.Config.Servers
---@field setup? {[string]: fun()}

local configs = require("config")

---@param opts? lsp.ClientCapabilities
local make_client_capabilities = function(opts)
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  capabilities =
    vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())
  capabilities =
    vim.tbl_deep_extend("force", capabilities, require("nvchad.configs.lspconfig").capabilities)
  return vim.tbl_deep_extend("force", capabilities, opts or {})
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
    },

    severity_sort = true,
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = configs.icons.diagnostics.error,
        [vim.diagnostic.severity.WARN] = configs.icons.diagnostics.warning,
        [vim.diagnostic.severity.HINT] = configs.icons.diagnostics.hint,
        [vim.diagnostic.severity.INFO] = configs.icons.diagnostics.info,
      },
    },

    float = {
      ---@diagnostic disable-next-line
      border = {
        { "┌", "CmpBorder" },
        { "─", "CmpBorder" },
        { "┐", "CmpBorder" },
        { "│", "CmpBorder" },
        { "┘", "CmpBorder" },
        { "─", "CmpBorder" },
        { "└", "CmpBorder" },
        { "│", "CmpBorder" },
      },
    },
  },

  inlay_hints = {
    enabled = false,
    exclude = {},
  },

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
      diagnostic = {
        dynamicRegistration = true,
      },
    },
    window = {
      workDoneProgress = true,
    },
  }),

  disable_default_settings = {
    roslyn = { "on_init" },
  },

  servers = {},
  setup = {},
}
