pcall(function()
  dofile(vim.g.base46_cache .. "syntax")
  dofile(vim.g.base46_cache .. "treesitter")
end)

return {

  ensure_installed = {
    "html",
    "css",
    "javascript",
    "typescript",
    "tsx",
    "c",
    "cpp",
    "python",
    "bash",
    "markdown",
    "sql",
    "prisma",
    "lua",
    "luadoc",
    "comment",
  },

  highlight = {
    enable = true,
  },

  indent = { enable = true },
}
