local plugins = { 
  {
    "williamboman/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUpdate" },
    opts = function()
      return require "nvchad.configs.mason" end,
  },
  {

    "neovim/nvim-lspconfig",
    event = { "BufReadPost", "BufWritePost", "BufNewFile" },
    dependencies = {
      { "williamboman/mason-lspconfig.nvim", config = function() end },
    },
    opts = require "plugins.lsp.lspconfig-opt",
    config = function()
      -- mapping each lspconfig-opt.servers.[server name].keys
      nvim.lsp.on_attach(function(client, buffer)
        require("plugins.lsp.keymaps").on_attach(client, buffer)
      end)

      -- setup servers
      require "plugins.lsp.lspconfig-config"

      nvim.lsp.on_dynamic_capability(require("plugins.lsp.keymaps").on_attach)
    end,
  },
}

return plugins
