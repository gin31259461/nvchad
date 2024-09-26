-- lsp server configurations: https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md

local M = {}

M.lsp = {}
M.mason = {}

-- { lsp_config_name, pkg_name }
local lsp_pkgs = {
  html = { "html", "html-lsp" },
  css = { "cssls", "css-lsp" },
  typescript = { "ts_ls", "typescript-language-server" },
  clangd = { "clangd", "clangd" },
  python = { "ruff_lsp", "ruff-lsp" },
  bash = { "bashls", "bash-language-server" },
  sql = { "sqls", "sqls" },
}

local fmt_pkgs = { python = "ruff", bash = "shfmt", sql = "sqlfluff" }

for v in pairs(lsp_pkgs) do
  table.insert(M.lsp, lsp_pkgs[v][1])
  table.insert(M.mason, lsp_pkgs[v][2])
end

for v in pairs(fmt_pkgs) do
  table.insert(M.mason, fmt_pkgs[v])
end

return M
