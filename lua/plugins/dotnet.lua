return {
  {
    dir = vim.fn.stdpath("config") .. "/dev/dotnet-cli.nvim",
    cmd = { "DotnetManager", "DotnetBuild", "DotnetPublish", "DotnetGlobalJson" },
    ft = "cs",
    opts = {},
  },
}
