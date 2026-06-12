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

  -- https://github.com/nickjvandyke/opencode.nvim
  {
    "nickjvandyke/opencode.nvim",
    version = "*", -- Latest stable release
    keys = {
      { "<leader>aa", desc = "opencode ask", mode = { "n", "x" } },
      { "<leader>ax", desc = "opencode select", mode = { "n", "x" } },
      { "<M-o>", desc = "opencode toggle", mode = "n" },
      {
        "<leader>ar",
        desc = "opencode operator",
        mode = { "n", "x" },
        expr = true,
      },
      {
        "<leader>al",
        desc = "opencode operator line",
        mode = "n",
        expr = true,
      },
      { "<S-C-u>", desc = "opencode scroll up", mode = "n" },
      { "<S-C-d>", desc = "opencode scroll down", mode = "n" },
    },
    config = function()
      local opencode = require("opencode")
      local term = require("nvchad.term")

      ---@type opencode.Opts
      vim.g.opencode_opts = {
        server = {
          start = false,
        },
      }

      vim.keymap.set({ "n", "x" }, "<leader>aa", function()
        opencode.ask("@this: ")
      end, { desc = "opencode ask" })

      vim.keymap.set({ "n", "x" }, "<leader>ax", function()
        opencode.select()
      end, { desc = "opencode select" })

      vim.keymap.set({ "n", "t" }, "<M-o>", function()
        term.toggle({
          cmd = "opencode --port",
          pos = "float",
          id = "opencode",
        })
      end, { desc = "opencode toggle" })

      vim.keymap.set({ "n", "x" }, "<leader>ar", function()
        return opencode.operator("@this ")
      end, { desc = "opencode operator", expr = true })

      vim.keymap.set("n", "<leader>al", function()
        return opencode.operator("@this ") .. "_"
      end, { desc = "opencode operator line", expr = true })

      vim.keymap.set("n", "<S-C-u>", function()
        opencode.command("session.half.page.up")
      end, { desc = "opencode scroll up" })

      vim.keymap.set("n", "<S-C-d>", function()
        opencode.command("session.half.page.down")
      end, { desc = "opencode scroll down" })

      -- Handle `opencode` events
      vim.api.nvim_create_autocmd("User", {
        pattern = "OpencodeEvent:*", -- Optionally filter event types
        callback = function(args)
          ---@type opencode.server.Event
          local event = args.data.event
          ---@type string
          local url = args.data.url

          -- See the available event types and their properties
          -- vim.notify(vim.inspect(event))

          -- Do something useful
          if event.type == "session.idle" then
            vim.notify("`opencode` finished responding")
          end
        end,
      })
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
