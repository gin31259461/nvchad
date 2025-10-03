---@type LazySpec[]
return {
  -- default keymaps: https://github.com/nvim-telescope/telescope.nvim?tab=readme-ov-file#default-mappings
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    cmd = "Telescope",
    opts = {
      defaults = {
        prompt_prefix = "   ",
        selection_caret = " ",
        entry_prefix = " ",
        sorting_strategy = "ascending",
        layout_config = {
          horizontal = {
            prompt_position = "top",
            preview_width = 0.55,
          },
          width = 0.87,
          height = 0.80,
        },
        mappings = {
          n = { ["q"] = require("telescope.actions").close },
        },
      },

      -- extensions_list = { "themes", "terms", "noice" },
      extensions = { "noice" },
    },
    config = function(_, opts)
      -- pcall(function()
      --   dofile(vim.g.base46_cache .. "telescope")
      -- end)

      local telescope = require("telescope")

      for _, v in ipairs(opts.extensions) do
        telescope.load_extension(v)
      end

      telescope.setup(opts)
    end,
  },

  {
    "gin31259461/harpoon",
    -- "ThePrimeagen/harpoon",
    event = "VeryLazy",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
    ---@type HarpoonPartialConfig
    opts = {
      -- https://github.com/ThePrimeagen/harpoon/blob/harpoon2/lua/harpoon/config.lua
      default = {
        -- refer to: https://github.com/ThePrimeagen/harpoon/issues/523#issuecomment-1984926994
        --
        create_list_item = function(config, value)
          value = value
            or NvChad.fs.normalize_path(
              vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf()),
              config.get_root_dir()
            )

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
              short_path = NvChad.fs.pretty_path(
                value,
                { length = NvChad.ui.harpoon.short_path_length, only_cwd = true }
              ),
            },
          }
        end,

        display = function(list_item)
          local path = list_item.context.short_path or ""
          return NvChad.ui.harpoon.format_display(path)
        end,
      },
    },
    ---@param opts HarpoonPartialConfig
    config = function(_, opts)
      local harpoon = require("harpoon")

      harpoon:setup(opts)

      -- this will set cursor to current file
      harpoon:extend(NvChad.ui.harpoon.highlight_current_file())

      vim.keymap.set("n", "<leader>a", function()
        harpoon:list():add()
      end, { desc = "Buffer add into harpoon list" })

      -- Toggle previous & next buffers stored within Harpoon list
      vim.keymap.set("n", "<M-S-p>", function()
        harpoon:list():prev()
      end, { desc = "Toggle previous of harpoon list" })

      vim.keymap.set("n", "<M-S-n>", function()
        harpoon:list():next()
      end, { desc = "Toggle next of harpoon list" })

      -- https://github.com/ThePrimeagen/harpoon/issues/491
      -- currently, telescope is broken on windows so using simple menu

      vim.keymap.set("n", "<C-e>", function()
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end)

      vim.keymap.set("n", "<C-s>", function()
        harpoon.ui:save()
        harpoon.ui:close_menu()
      end)
    end,
  },
}
