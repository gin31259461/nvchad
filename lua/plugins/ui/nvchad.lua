---@type LazySpec[]
return {
  {
    "nvchad/ui",
    cond = false, -- replaced by Orbit-Lua/nvchad-ui fork
    lazy = false,
    config = function()
      require("nvchad")
    end,
  },

  {
    "Orbit-Lua/nvchad-ui",
    lazy = false,
    config = function()
      require("nvchad")
    end,
  },
}
