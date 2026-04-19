return {
  {
    dir = vim.fn.stdpath("data") .. "/dev/dotnet-cli.nvim",
    cmd = { "DotnetManager", "DotnetBuild", "DotnetPublish", "DotnetGlobalJson" },
    ft = "cs",
    opts = {},
  },
}
