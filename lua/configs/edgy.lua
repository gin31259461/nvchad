local options = {
  right = {
    {
      title = "Database",
      ft = "dbui",
      pinned = true,
      width = 0.3,
      open = function()
        vim.cmd "DBUI"
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
}

return options
