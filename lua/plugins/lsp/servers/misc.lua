---@type Lsp.Server.Module
return {
  servers = {
    prismals = {
      keys = {
        {
          "<leader>fp",
          function()
            require("conform").format({ lsp_fallback = true })
            vim.cmd("e!")
          end,
          desc = "prisma format file and force reload",
        },
      },
    },

    powershell_es = {
      bundle_path = "C:/PSES",
      shell = "powershell",
    },

    -- copilot.lua only works with its own copilot lsp server
    copilot = { enabled = false },
  },
}
