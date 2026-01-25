pcall(function()
  dofile(vim.g.base46_cache .. "git")
end)

---@type LazySpec[]
return {
  {
    "lewis6991/gitsigns.nvim",
    event = "User FilePost",
    opts = {
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
        untracked = { text = "▎" },
      },
      signs_staged = {
        add = { text = Core.config.icons.git.added },
        change = { text = Core.config.icons.git.modified },
        delete = { text = Core.config.icons.git.removed },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
      },
    },
  },

  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    build = { "pnpm install", "cd app", "pnpm install" },
    init = function()
      vim.g.mkdp_filetypes = { "markdown" }
    end,
    ft = { "markdown" },
  },

  {
    "folke/which-key.nvim",
    lazy = false,
    keys = { "<leader>", "<c-r>", "<c-w>", '"', "'", "`", "c", "v", "g" },
    cmd = "WhichKey",
    opts = function()
      dofile(vim.g.base46_cache .. "whichkey")

      ---@module "which-key"
      ---@type wk.Opts
      return {
        ---@type false | "classic" | "modern" | "helix"
        preset = "helix",
      }
    end,
  },
}
