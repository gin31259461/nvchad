local function normalize_path(buf_name, root)
  local Path_ready, Path = pcall(require, "plenary.path")

  if Path_ready then
    return Path:new(buf_name):make_relative(root)
  end

  return ""
end

local function to_exact_name(value)
  return "^" .. value .. "$"
end

---@type LazySpec
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
      extensions_list = { "noice" },
      extensions = {},
    },
    config = function(_, opts)
      pcall(function()
        dofile(vim.g.base46_cache .. "telescope")
      end)

      local telescope = require("telescope")

      for _, v in ipairs(opts.extensions_list) do
        telescope.load_extension(v)
      end

      telescope.setup(opts)
    end,
  },

  {
    "ThePrimeagen/harpoon",
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
            or normalize_path(vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf()), config.get_root_dir())

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
    ---@param opts HarpoonPartialConfig
    config = function(_, opts)
      local harpoon = require("harpoon")
      local Extensions = require("harpoon.extensions")

      ---@param list HarpoonList
      ---@param bufnr? integer
      local function update_harpoon_item_position(list, bufnr)
        bufnr = bufnr or vim.api.nvim_get_current_buf()
        local bufname = normalize_path(vim.api.nvim_buf_get_name(bufnr), list.config.get_root_dir())
        local item = list:get_by_value(bufname)

        if item then
          local pos = vim.api.nvim_win_get_cursor(0)

          item.context.row = pos[1]
          item.context.col = pos[2]

          Extensions.extensions:emit(Extensions.event_names.POSITION_UPDATED, item)
        end
      end

      -- default code: https://github.com/ThePrimeagen/harpoon/blob/ed1f853847ffd04b2b61c314865665e1dadf22c7/lua/harpoon/config.lua#L96
      opts.default.select = function(list_item, list, options)
        if list_item == nil then
          return
        end

        options = options or {}

        local bufnr = vim.fn.bufnr(to_exact_name(list_item.value))

        -- when close buffer, not quit neovim, bufnr will still exists,
        -- so I remove set_position to fix cursor position not set bug
        if bufnr == -1 then -- must create a buffer!
          -- bufnr = vim.fn.bufnr(list_item.value, true)
          bufnr = vim.fn.bufadd(list_item.value)
        end

        if not vim.api.nvim_buf_is_loaded(bufnr) then
          vim.fn.bufload(bufnr)
          vim.api.nvim_set_option_value("buflisted", true, {
            buf = bufnr,
          })
        end

        if options.vsplit then
          vim.cmd("vsplit")
        elseif options.split then
          vim.cmd("split")
        elseif options.tabedit then
          vim.cmd("tabedit")
        end

        vim.api.nvim_set_current_buf(bufnr)

        local lines = vim.api.nvim_buf_line_count(bufnr)

        local edited = false
        if list_item.context.row > lines then
          list_item.context.row = lines
          edited = true
        end

        local row = list_item.context.row
        local row_text = vim.api.nvim_buf_get_lines(0, row - 1, row, false)
        local col = #row_text[1]

        if list_item.context.col > col then
          list_item.context.col = col
          edited = true
        end

        vim.api.nvim_win_set_cursor(0, {
          list_item.context.row or 1,
          list_item.context.col or 0,
        })

        if edited then
          Extensions.extensions:emit(Extensions.event_names.POSITION_UPDATED, {
            list_item = list_item,
          })
        end

        Extensions.extensions:emit(Extensions.event_names.NAVIGATE, {
          buffer = bufnr,
        })
      end

      opts.default.BufLeave = function(arg, list)
        update_harpoon_item_position(list, arg.buf)
      end

      harpoon:setup(opts)

      -- this will set cursor to current file
      harpoon:extend(NvChad.ui.harpoon.highlight_current_file())

      vim.keymap.set("n", "<leader>a", function()
        local list = harpoon:list():add()
        -- default behavior will not save cursor position when item is exists in harpoon list
        -- so I update item manually
        update_harpoon_item_position(list)
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
