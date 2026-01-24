local M = {}

M.lsp_servers = {}
M.mason_ensure_installed = {}

---@type table<string, string> --- lsp_config_name, package_name_in_mason
local pkgs_with_lsp_setup = {
  ------------------- python  -------------------

  -- lsp
  -- jedi_language_server = "jedi-language-server",
  -- pylsp = "python-lsp-server",

  -- static type checker
  -- pyright performance issue: https://www.reddit.com/r/neovim/comments/1mgwt7p/neovim_pyright_lsp_is_super_slow_compared_to/
  pyright = "pyright",

  -- https://github.com/facebook/pyrefly
  -- pyrefly = "pyrefly",

  -- linter
  ruff = "ruff",

  ------------------- .NET -------------------
  -- also need dotnet-sdk to be installed: https://dotnet.microsoft.com/zh-tw/download
  -- csharp = { "omnisharp", "omnisharp" },
  --
  -- requirement:
  -- .NET 10.0 SDK: https://dotnet.microsoft.com/zh-tw/download/dotnet/10.0
  roslyn = "roslyn",

  ------------------- Web -------------------
  html = "html-lsp",
  cssls = "css-lsp",
  -- vtsls = "vtsls",
  -- ts_ls = "typescript-language-server",

  ------------------- Docker -------------------
  dockerls = "dockerfile-language-server",
  docker_compose_language_service = "docker-compose-language-service",

  ------------------- other -------------------

  clangd = "clangd",
  bashls = "bash-language-server",
  marksman = "marksman",
  prismals = "prisma-language-server",
  tombi = "tombi",
  jsonls = "json-lsp",
  lua_ls = "lua-language-server",
  sqls = "sqls",

  -- also need install bundle from: https://github.com/PowerShell/PowerShellEditorServices
  -- extract zip file to C:/PSES
  powershell_es = "powershell-editor-services",

  -- xml
  lemminx = "lemminx",
}

-- formatter and linter
local pkgs_only = {
  "stylua",
  "deno",
  "shfmt",
  "sqlfluff",
  "hadolint",
  "markdownlint",
  "markdownlint-cli2",
  "markdown-toc",
  "prettier",
  "eslint_d",
  "sql-formatter",
  "csharpier",
  "netcoredbg",
  "typescript-language-server",
}

for lsp_config_name, pkg_name_in_mason in pairs(pkgs_with_lsp_setup) do
  table.insert(M.lsp_servers, lsp_config_name)
  table.insert(M.mason_ensure_installed, pkg_name_in_mason)
end

for _, v in ipairs(pkgs_only) do
  table.insert(M.mason_ensure_installed, v)
end

return M
