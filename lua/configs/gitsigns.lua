dofile(vim.g.base46_cache .. "git")

return {
  signs = {
    add = { text = "▎" },
    change = { text = "▎" },
    delete = { text = "" },
    topdelete = { text = "" },
    changedelete = { text = "▎" },
    untracked = { text = "▎" },
  },
  signs_staged = {
    add = { text = nvim.configs.icons.git.added },
    change = { text = nvim.configs.icons.git.modified },
    delete = { text = nvim.configs.icons.git.removed },
    topdelete = { text = "" },
    changedelete = { text = "▎" },
  },
}
