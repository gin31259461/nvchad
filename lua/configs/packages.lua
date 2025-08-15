local M = {}

M.lsp_servers = {}
M.mason_ensure_installed = {}

-- alias = { lsp_config_name, pkg_name }
local pkgs_with_setup = {
  ------------------- python services -------------------

  -- pyright performance issue: https://www.reddit.com/r/neovim/comments/1mgwt7p/neovim_pyright_lsp_is_super_slow_compared_to/

  -- python_lsp = { "jedi_language_server", "jedi-language-server" },
  -- python_lsp = { "pylsp", "python-lsp-server" },

  -- https://github.com/facebook/pyrefly
  -- python_type_checker = { "pyrefly", "pyrefly" },

  python_type_checker = { "pyright", "pyright" },
  python_linter = { "ruff", "ruff" },

  ------------------- other services -------------------

  -- docker
  docker = { "dockerls", "dockerfile-language-server" },
  docker_compose = { "docker_compose_language_service", "docker-compose-language-service" },

  -- web
  html = { "html", "html-lsp" },
  css = { "cssls", "css-lsp" },
  js = { "vtsls", "vtsls" },
  -- ts = { "ts_ls", "typescript-language-server" },

  -- other
  clangd = { "clangd", "clangd" },
  bash = { "bashls", "bash-language-server" },
  markdown = { "marksman", "marksman" },
  prisma = { "prismals", "prisma-language-server" },
  toml = { "taplo", "taplo" },
  json = { "jsonls", "json-lsp" },
  lua = { "lua_ls", "lua-language-server" },

  -- also need install bundle from: https://github.com/PowerShell/PowerShellEditorServices
  -- extract zip file to C:/PSES
  powershell = { "powershell_es", "powershell-editor-services" },

  -- also need dotnet-sdk to be installed: https://dotnet.microsoft.com/zh-tw/download
  csharp = { "omnisharp", "omnisharp" },
}

-- formatter and linter
local pkgs_only = {
  "stylua",
  "deno",
  "shfmt",
  "sqlfluff",
  "hadolint",
  "markdownlint-cli2",
  "markdown-toc",
  "prettier",
  "eslint_d",
  "sql-formatter",
  "csharpier",
  "netcoredbg",
}

for v in pairs(pkgs_with_setup) do
  table.insert(M.lsp_servers, pkgs_with_setup[v][1])
  table.insert(M.mason_ensure_installed, pkgs_with_setup[v][2])
end

for _, v in ipairs(pkgs_only) do
  table.insert(M.mason_ensure_installed, v)
end

return M
