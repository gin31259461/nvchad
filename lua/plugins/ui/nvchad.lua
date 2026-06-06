---@type LazySpec[]
return {
  {
    "nvchad/base46",
    cond = false,
  },
  {
    "Orbit-Lua/nv-base46",
    build = function()
      require("base46").load_all_highlights()
    end,
  },

  {
    "nvchad/ui",
    cond = false,
  },
  {
    "Orbit-Lua/nv-ui",
    lazy = false,
    config = function()
      require("nvchad")
    end,
  },
}
