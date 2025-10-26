if not vim.g.enable_db_plugins then
  return {}
end

---@type LazySpec[]
return {
  {
    "kristijanhusak/vim-dadbod-completion",
    dependencies = {
      {
        "tpope/vim-dadbod",
        cmd = "DB",
      },
    },
    ft = NvChad.ft.sql_ft,
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = NvChad.ft.sql_ft,
        callback = function()
          local cmp = require("cmp")

          local sources = vim.tbl_map(function(source)
            return { name = source.name }
          end, cmp.get_config().sources)

          -- add vim-dadbod-completion source
          table.insert(sources, { name = "vim-dadbod-completion" })

          -- update sources for the current buffer
          cmp.setup.buffer({ sources = sources })
        end,
      })
    end,
  },

  {
    "kristijanhusak/vim-dadbod-ui",
    -- event = { "VeryLazy" },
    ft = NvChad.ft.sql_ft,
    cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
    dependencies = "tpope/vim-dadbod",
    keys = {
      { "<leader>dD", "<cmd>DBUIToggle<CR>", desc = "Toggle DBUI" },
      { "<leader>dA", "<cmd>DBUIFindBuffer<CR>", desc = "Add buffer files to DBUI" },
    },
    init = function()
      local data_path = vim.fn.stdpath("data")
      local config_path = vim.fn.stdpath("config")

      vim.g.db_ui_auto_execute_table_helpers = 1
      vim.g.db_ui_save_location = data_path .. "/dadbod_ui"
      vim.g.db_ui_show_database_icon = true
      vim.g.db_ui_tmp_query_location = data_path .. "/dadbod_ui/tmp"
      vim.g.db_ui_use_nerd_fonts = true
      vim.g.db_ui_use_nvim_notify = true

      -- NOTE: The default behavior of auto-execution of queries on save is disabled
      -- this is useful when you have a big query that you don't want to run every time
      -- you save the file running those queries can crash neovim to run use the
      -- default keymap: <leader>S
      vim.g.db_ui_execute_on_save = false

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "dbout",
        callback = function()
          vim.wo.foldenable = false
        end,
      })

      vim.keymap.set("n", "<leader>dC", function()
        vim.cmd("edit " .. NvChad.str.rstrip_slash(vim.g.db_ui_save_location) .. "/connections.json")
      end, { desc = "Open Connection Config" })

      vim.keymap.set("n", "<leader>dT", function()
        vim.cmd("edit " .. config_path .. "/lua/plugins/db/template")
      end, { desc = "Open DB Config Template" })

      vim.filetype.add({
        pattern = { ["*-[Columns|Primary Keys|Indexes|References|Constraints|Foreign Keys|Describe]-[^%.]*"] = "sql" },
      })
    end,
  },

  {
    "folke/edgy.nvim",
    ft = "dbui",
    opts = {
      right = {
        {
          title = "Database",
          ft = "dbui",
          pinned = true,
          width = 0.3,
          open = function()
            vim.cmd("DBUI")
          end,
        },
      },

      bottom = {
        {
          title = "DB Query Result",
          pinned = true,
          ft = "dbout",
        },
      },

      options = {
        bottom = {
          size = 30,
        },
      },
    },
  },
}
