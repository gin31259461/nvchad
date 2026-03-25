---@type LazySpec[]
return {
  {
    "nvchad/ui",
    cond = false, -- replaced by gin31259461/nvchad-ui fork
    lazy = false,
    config = function()
      require("nvchad")
    end,
  },

  {
    "gin31259461/nvchad-ui",
    lazy = false,
    config = function()
      require("nvchad")
    end,
  },
}
