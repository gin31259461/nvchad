local M = {}

---Activates optional LSP features (inlay hints, code lens) based on config.
---Requires Neovim >= 0.10; no-ops on earlier versions.
---@param opts Lsp.Config.Spec
M.activate = function(opts)
  if vim.fn.has("nvim-0.10") == 0 then
    return
  end

  local utils_lsp = require("utils.lsp")

  if opts.inlay_hints.enabled then
    utils_lsp.on_supports_method("textDocument/inlayHint", function(_, buffer)
      if
        vim.api.nvim_buf_is_valid(buffer)
        and vim.bo[buffer].buftype == ""
        and not vim.tbl_contains(
          opts.inlay_hints.exclude,
          vim.bo[buffer].filetype
        )
      then
        vim.lsp.inlay_hint.enable(true, { bufnr = buffer })
      end
    end)
  end

  if opts.codelens.enabled and vim.lsp.codelens then
    utils_lsp.on_supports_method("textDocument/codeLens", function(_, bufnr)
      vim.lsp.codelens.enable(true)
      vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
        buffer = bufnr,
        callback = function()
          vim.lsp.codelens.enable(true, { bufnr = bufnr })
        end,
      })
    end)
  end
end

return M
