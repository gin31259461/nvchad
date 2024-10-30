-- lsp server configurations: https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md

local M = {}

M.lsp = {}
M.mason = {}

-- alias = { lsp_config_name, pkg_name }
local lsp_pkgs = {
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
  typescirpt = { "vtsls", "vtsls" },
  deno = { "denols", "deno" },

  -- other
  clangd = { "clangd", "clangd" },
  bash = { "bashls", "bash-language-server" },
  markdown = { "marksman", "marksman" },
  prisma = { "prismals", "prisma-language-server" },
  toml = { "taplo", "taplo" },
  json = { "jsonls", "json-lsp" },
}

-- formatter and linter
local other_pkgs = {
  "ruff",
  "shfmt",
  "sqlfluff",
  "hadolint",
  "markdownlint-cli2",
  "markdown-toc",
  "prettier",
  "eslint_d",
  "sql-formatter",
}

for v in pairs(lsp_pkgs) do
  table.insert(M.lsp, lsp_pkgs[v][1])
  table.insert(M.mason, lsp_pkgs[v][2])
end

for _, v in ipairs(other_pkgs) do
  table.insert(M.mason, v)
end

return M
