-- lsp server configurations: https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md

local M = {}

M.lsp = {}
M.mason = {}

-- { lsp_config_name, pkg_name }
local lsp_pkgs = {
  clangd = { "clangd", "clangd" },
  bash = { "bashls", "bash-language-server" },
  sql = { "sqls", "sqls" },
  markdown = { "marksman", "marksman" },

  -- python
  python = { "pylsp", "python-lsp-server" },
  pyright = { "pyright", "pyright" },
  ruff = { "ruff_lsp", "ruff-lsp" },

  -- docker
  docker = { "dockerls", "dockerfile-language-server" },
  docker_compose = { "docker_compose_language_service", "docker-compose-language-service" },

  -- web
  html = { "html", "html-lsp" },
  css = { "cssls", "css-lsp" },
  -- deno support typescript and javascript language server
  deno = { "denols", "deno" },
}

local formatter_pkgs = { python = "ruff", bash = "shfmt", sql = "sqlfluff" }
local linter_pkgs = {
  docker = "hadolint",

  -- markdown
  markdownlint_cli = "markdownlint-cli2",
  markdown_toc = "markdown-toc",
}

for v in pairs(lsp_pkgs) do
  table.insert(M.lsp, lsp_pkgs[v][1])
  table.insert(M.mason, lsp_pkgs[v][2])
end

for v in pairs(formatter_pkgs) do
  table.insert(M.mason, formatter_pkgs[v])
end

for v in pairs(linter_pkgs) do
  table.insert(M.mason, formatter_pkgs[v])
end

return M
