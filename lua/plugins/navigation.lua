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
    event = "VeryLazy",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
    ---@type HarpoonPartialConfig
    opts = {
      default = {
        -- refer to: https://github.com/ThePrimeagen/harpoon/issues/523#issuecomment-1984926994
        create_list_item = function(config, value)
          value = value or vim.fs.normalize(vim.fn.expand("%:p"))

          local bufnr = vim.fn.bufnr(value, false)
          local pos = { 1, 0 }

          if bufnr ~= -1 then
            pos = vim.api.nvim_win_get_cursor(0)
          end

          return {
            value = value,
            context = {
              row = pos[1],
              col = pos[2],
              short_path = NvChad.root.pretty_path(value, { length = NvChad.ui.harpoon.short_path_length }),
            },
          }
        end,

        display = function(list_item)
          local path = list_item.context.short_path or ""
          local icon = NvChad.ui.get_file_icon(path)
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
      vim.keymap.set("n", "<S-p>", function()
        harpoon:list():prev()
      end, { desc = "Toggle previous of harpoon list" })

      vim.keymap.set("n", "<S-n>", function()
        harpoon:list():next()
      end, { desc = "Toggle next of harpoon list" })

      vim.keymap.set("n", "<C-e>", function()
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end)

      vim.keymap.set("n", "<C-s>", function()
        harpoon.ui:save()
      end)

      -- https://github.com/ThePrimeagen/harpoon/issues/491
      -- currently, telescope is broken on windows
      --
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

      -- vim.keymap.set("n", "<C-e>", function()
      --   toggle_telescope(harpoon:list())
      -- end, { desc = "Open harpoon window" })
    end,
  },
}
