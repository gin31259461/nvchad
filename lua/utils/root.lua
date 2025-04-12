local M = {}

function M.get_root_dir()
  local path = vim.api.nvim_buf_get_name(0)
  local lsp_clients = vim.lsp.get_clients { bufnr = 0 }

  -- get root_dir from LSP config
  for _, client in ipairs(lsp_clients) do
    local root_dir = client.config and client.config.root_dir
    if root_dir and path:find(root_dir, 1, true) == 1 then
      return root_dir
    end
  end

  -- using lspconfig.util.root_pattern to find it
  local util = require "lspconfig.util"
  local root = util.root_pattern(".git", "package.json", "pyproject.toml")(path)
  if root then
    return root
  end

  -- fallback
  return vim.fn.getcwd()
end

return M
