dofile(vim.g.base46_cache .. "mason")

local utils_lsp = require("utils.lsp")

---@type LazySpec[]
local plugins = {
  {
    "williamboman/mason.nvim",
    event = "VeryLazy",
    cmd = { "Mason", "MasonInstall", "MasonUpdate" },
    opts = {
      PATH = "skip",

      ui = {
        icons = {
          package_pending = " ",
          package_installed = " ",
          package_uninstalled = " ",
        },
      },

      max_concurrent_installers = 10,

      registries = {
        "github:mason-org/mason-registry",
        "github:Crashdummyy/mason-registry",
      },
    },
  },

  {
    "neovim/nvim-lspconfig",
    lazy = false,
    event = { "BufReadPost", "BufWritePost", "BufNewFile" },

    opts = function()
      return require("plugins.lsp.config")
    end,

    ---@module "plugins.lsp.config"
    ---@param _ LazyPlugin
    ---@param opts Lsp.Config.Spec
    config = function(_, opts)
      utils_lsp.on_attach(function(client, buffer)
        require("plugins.lsp.keymaps").on_attach(client, buffer)
      end)

      require("plugins.lsp.setup")

      utils_lsp.setup()
      utils_lsp.on_dynamic_capability(require("plugins.lsp.keymaps").on_attach)

      require("plugins.lsp.diagnostics").configure(opts)
      require("plugins.lsp.diagnostics").install_filter_middleware()
      require("plugins.lsp.features").activate(opts)
    end,
  },

  { "microsoft/python-type-stubs" },

  -- https://github.com/seblyng/roslyn.nvim?tab=readme-ov-file#%EF%B8%8F-configuration
  {
    "seblyng/roslyn.nvim",
    ft = { "cs" },
    ---@module 'roslyn.config'
    ---@type RoslynNvimConfig
    opts = {
      filewatching = "roslyn",
      silent = true,
    },
  },
}

vim.list_extend(plugins, require("plugins.lsp.typescript-tools"))

return plugins
