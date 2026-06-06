local utils = require("utils")
local utils_cmp = require("utils.cmp")

---@type LazySpec[]
local specs = {

  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    build = ":Copilot auth",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      suggestion = {
        enabled = not vim.g.ai_cmp,
        auto_trigger = true,
        hide_during_completion = vim.g.ai_cmp,
        keymap = {
          accept = false, -- handled by nvim-cmp / blink.cmp
          next = "<M-]>",
          prev = "<M-[>",
        },
      },
      panel = { enabled = false },
      filetypes = {
        markdown = true,
        help = true,
      },
      copilot_model = vim.g.copilot_model,
    },
  },

  -- add ai_accept action
  {
    "zbirenbaum/copilot.lua",
    opts = function()
      utils_cmp.actions.ai_accept = function()
        if require("copilot.suggestion").is_visible() then
          utils.create_undo()
          require("copilot.suggestion").accept()
          return true
        end
      end

      vim.keymap.set(
        "i",
        "<M-l>",
        utils_cmp.actions.ai_accept,
        { desc = "accept ai suggestion" }
      )
    end,
  },

  {
    "nickjvandyke/opencode.nvim",
    version = "*", -- Latest stable release
    dependencies = {
      {
        -- `snacks.nvim` integration is recommended, but optional
        ---@module "snacks" <- Loads `snacks.nvim` types for configuration intellisense
        "folke/snacks.nvim",
        optional = true,
        opts = {
          input = {}, -- Enhances `ask()`
          picker = { -- Enhances `select()`
            actions = {
              opencode_send = function(...)
                return require("opencode").snacks_picker_send(...)
              end,
            },
            win = {
              input = {
                keys = {
                  ["<a-a>"] = { "opencode_send", mode = { "n", "i" } },
                },
              },
            },
          },
        },
      },
    },
    keys = {
      {
        "<leader>aa",
        function()
          require("opencode").ask("@this: ", { submit = true })
        end,
        mode = { "n", "x" },
        desc = "ask opencode…",
      },
      {
        "<leader>ax",
        function()
          require("opencode").select()
        end,
        mode = { "n", "x" },
        desc = "execute opencode action…",
      },
      {
        "<leader>at",
        function()
          require("opencode").toggle()
        end,
        mode = "n",
        desc = "toggle opencode",
      },
      {
        "<leader>ar",
        function()
          return require("opencode").operator("@this ")
        end,
        mode = { "n", "x" },
        desc = "add range to opencode",
        expr = true,
      },
      {
        "<leader>al",
        function()
          return require("opencode").operator("@this ") .. "_"
        end,
        mode = "n",
        desc = "add line to opencode",
        expr = true,
      },
      {
        "<S-C-u>",
        function()
          require("opencode").command("session.half.page.up")
        end,
        mode = "n",
        desc = "scroll opencode up",
      },
      {
        "<S-C-d>",
        function()
          require("opencode").command("session.half.page.down")
        end,
        mode = "n",
        desc = "scroll opencode down",
      },
    },
    config = function()
      ---@type opencode.Opts
      vim.g.opencode_opts = {
        -- Your configuration, if any; goto definition on the type or field for details
      }
    end,
  },
}

-- refer to: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/plugins/extras/ai/copilot.lua
if vim.g.ai_cmp then
  table.insert(specs, {
    -- copilot cmp source
    "hrsh7th/nvim-cmp",
    optional = true,
    dependencies = { -- this will only be evaluated if nvim-cmp is enabled
      {
        "zbirenbaum/copilot-cmp",
        opts = {},
        config = function(_, opts)
          local copilot_cmp = require("copilot_cmp")
          copilot_cmp.setup(opts)
          -- attach cmp source whenever copilot attaches
          -- fixes lazy-loading issues with the copilot cmp source
          require("snacks").util.lsp.on({ name = "copilot" }, function()
            copilot_cmp._on_insert_enter({})
          end)
        end,
        specs = {
          {
            "hrsh7th/nvim-cmp",
            optional = true,
            ---@param opts cmp.ConfigSchema
            opts = function(_, opts)
              table.insert(opts.sources, 1, {
                name = "copilot",
                group_index = 1,
                priority = 100,
              })
            end,
          },
        },
      },
    },
  })
end

return specs
