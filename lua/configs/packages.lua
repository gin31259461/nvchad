local M = {}

M.lsp_servers = {}
M.mason_ensure_installed = {}

-- alias = { lsp_config_name, pkg_name }
local pkgs_with_setup = {
  -- python
  pyright = { "pyright", "pyright" },
  ruff = { "ruff", "ruff" },

  -- docker
  docker = { "dockerls", "dockerfile-language-server" },
  docker_compose = { "docker_compose_language_service", "docker-compose-language-service" },

  -- web
  html = { "html", "html-lsp" },
  css = { "cssls", "css-lsp" },
  vtsls = { "vtsls", "vtsls" },

  -- other
  clangd = { "clangd", "clangd" },
  bash = { "bashls", "bash-language-server" },
  markdown = { "marksman", "marksman" },
  prisma = { "prismals", "prisma-language-server" },
  toml = { "taplo", "taplo" },
  json = { "jsonls", "json-lsp" },
}

-- formatter and linter
local pkgs_only = {
  "python-lsp-server",
  "deno",
  "shfmt",
  "sqlfluff",
  "hadolint",
  "markdownlint-cli2",
  "markdown-toc",
  "prettier",
  "eslint_d",
  "sql-formatter",
}

for v in pairs(pkgs_with_setup) do
  table.insert(M.lsp_servers, pkgs_with_setup[v][1])
  table.insert(M.mason_ensure_installed, pkgs_with_setup[v][2])
end

for _, v in ipairs(pkgs_only) do
  table.insert(M.mason_ensure_installed, v)
end

return M
