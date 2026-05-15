local services = require("config.services")

local M = {}

M.treesitter_ensure_installed = {
  "lua",
  "luadoc",
  "printf",
  "vim",
  "vimdoc",
  "html",
  "css",
  "javascript",
  "typescript",
  "tsx",
  "c",
  "cpp",
  "python",
  "bash",
  "markdown",
  "sql",
  "prisma",
  "comment",
  "c_sharp",
  "xml",
  "go",
  "regex",
}

-- Mason packages that are installed but not tracked as managed services.
local mason_extras = {
  "markdownlint", -- standalone markdown linter (separate from markdownlint-cli2)
}

-- Derive lsp_servers and mason_ensure_installed from the services registry so that
-- config/services.lua is the single source of truth for all managed services.
M.lsp_servers = {}
M.mason_ensure_installed = {}

local seen = {}
local function add_mason(pkg)
  if pkg and not seen[pkg] then
    seen[pkg] = true
    table.insert(M.mason_ensure_installed, pkg)
  end
end

for name, meta in pairs(services.lsp) do
  table.insert(M.lsp_servers, name)
  add_mason(meta.mason)
end

for _, cat in ipairs({ "dap", "linter", "formatter" }) do
  for _, meta in pairs(services[cat]) do
    add_mason(meta.mason)
  end
end

for _, pkg in ipairs(mason_extras) do
  add_mason(pkg)
end

return M
