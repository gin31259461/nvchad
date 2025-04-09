local plugins = {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPost", "BufWritePost", "BufNewFile" },
    dependencies = {
      "mason.nvim",
      { "williamboman/mason-lspconfig.nvim", config = function() end },
    },
    opts = require "plugins.lsp.lspconfig-opt",
    config = function()
      local lsp = require "utils.lsp"

      -- mapping each lspconfig-opt.servers.[server name].keys
      lsp.on_attach(function(client, buffer)
        require("plugins.lsp.keymaps").on_attach(client, buffer)
      end)

      -- setup servers
      require "plugins.lsp.lspconfig-config"

      lsp.on_dynamic_capability(require("plugins.lsp.keymaps").on_attach)
    end,
  },
}

return plugins
