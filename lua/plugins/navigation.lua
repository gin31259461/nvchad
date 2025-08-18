---@type LazySpec
return {

  -- default keymaps: https://github.com/nvim-telescope/telescope.nvim?tab=readme-ov-file#default-mappings
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    cmd = "Telescope",
    opts = function(_, opts)
      -- local actions = require("telescope.actions")
      local nvchad_telescope_opts = require("nvchad.configs.telescope")

      opts = vim.tbl_deep_extend("force", opts, nvchad_telescope_opts)
    end,
  },

  {
    "ThePrimeagen/harpoon",
    lazy = false,
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
    ---@type HarpoonPartialConfig
    opts = {
      default = {
        create_list_item = function(_, item)
          return {
            value = NvChad.root.pretty_path(item.value, { length = 5 }),
            context = item.context,
          }
        end,
        display = function(list_item)
          local path = list_item.value
          local icon = NvChad.ui.get_file_icon(path)
          -- local path = NvChad.root.pretty_path(list_item.value, { length = 5 })
          return "  " .. icon .. " " .. path
        end,
      },
    },
    config = function(_, opts)
      local harpoon = require("harpoon")

      harpoon:setup(opts)
      -- this will set cursor to current file
      harpoon:extend(NvChad.ui.harpoon.highlight_current_file())

      vim.keymap.set("n", "<leader>a", function()
        harpoon:list():add()
      end, { desc = "Buffer add into harpoon list" })

      -- Toggle previous & next buffers stored within Harpoon list
      vim.keymap.set("n", "<C-S-P>", function()
        harpoon:list():prev()
      end, { desc = "Toggle previous of harpoon list" })

      vim.keymap.set("n", "<C-S-N>", function()
        harpoon:list():next()
      end, { desc = "Toggle next of harpoon list" })

      vim.keymap.set("n", "<C-e>", function()
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end)

      vim.keymap.set("n", "<C-s>", function()
        harpoon.ui:save()
      end)

      -- local conf = require("telescope.config").values
      -- local function toggle_telescope(harpoon_files)
      --   local file_paths = {}
      --   for _, item in ipairs(harpoon_files.items) do
      --     table.insert(file_paths, item.value)
      --   end
      --
      --   require("telescope.pickers")
      --     .new({}, {
      --       prompt_title = "Harpoon",
      --       finder = require("telescope.finders").new_table({
      --         results = file_paths,
      --       }),
      --       previewer = conf.file_previewer({}),
      --       sorter = conf.generic_sorter({}),
      --     })
      --     :find()
      -- end

      -- vim.keymap.set("n", "<C-h>", function()
      --   harpoon:list():select(1)
      -- end, { desc = "Select 1 of harpoon list" })
      --
      -- vim.keymap.set("n", "<C-t>", function()
      --   harpoon:list():select(2)
      -- end, { desc = "Select 2 of harpoon list" })
      --
      -- vim.keymap.set("n", "<C-n>", function()
      --   harpoon:list():select(3)
      -- end, { desc = "Select 3 of harpoon list" })
      --
      -- vim.keymap.set("n", "<C-s>", function()
      --   harpoon:list():select(4)
      -- end, { desc = "Select 4 of harpoon list" })

      -- vim.keymap.set("n", "<C-e>", function()
      --   toggle_telescope(harpoon:list())
      -- end, { desc = "Open harpoon window" })
    end,
  },
}
