---@type LazySpec[]
return {
  {
    "gin31259461/dotnet-cli.nvim",
    dependencies = { "gin31259461/comet.nvim" },
    cmd = { "DotnetManager", "DotnetBuild", "DotnetPublish", "DotnetGlobalJson" },
    ft = "cs",
    opts = {},
  },
}
