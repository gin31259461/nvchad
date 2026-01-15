-- vim.api.nvim_create_autocmd({ "BufEnter" }, {
--   pattern = "*",
--   callback = function()
--     if vim.bo.filetype == "" then
--       vim.cmd("filetype detect")
--     end
--   end,
-- })

-- FIX: roslyn progress spec issue: https://github.com/dotnet/roslyn/issues/79939
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "cs" },
  callback = function()
    vim.api.nvim_clear_autocmds({
      group = "noice_lsp_progress",
      event = "LspProgress",
      pattern = "*",
    })
  end,
})

-- FIX: statusline diagnostics missing on idle buffer open
vim.api.nvim_create_autocmd({ "DiagnosticChanged" }, {
  pattern = "*",
  callback = function()
    vim.cmd("redrawstatus")
  end,
})

-- FIX: (temp): issue: https://github.com/neovim/neovim/issues/8587
-- this method is from: https://github.com/neovim/neovim/issues/8587#issuecomment-2176399196
if NvChad.shell.is_win() then
  vim.api.nvim_create_user_command("ClearShada", function()
    local shada_path = vim.fn.expand(vim.fn.stdpath("data") .. "/shada")
    require("utils.fs").delete_files(shada_path, {
      success_message = "Successfully deleted all temporary shada files",
      skip_condition = function(file_name)
        if file_name == "main.shada" then
          return true
        end

        return false
      end,
    })
  end, { desc = "Clears all the .tmp shada files" })
end

local cmds = NvChad.fs.scandir(NvChad.fs.config_path .. "/lua/cmds", "file")
for _, v in ipairs(cmds) do
  require("cmds." .. vim.fn.fnamemodify(v, ":r"))
end
