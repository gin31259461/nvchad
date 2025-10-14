local M = {}

M.title = "Dotnet"

---@return string[]
M.get_csproj_files = function()
  return vim.fn.glob("*.csproj", false, true)
end

M.get_publish_cmd = function(project)
  return { "dotnet", "build", project, "-c", "Release", "-o", vim.fn.getcwd() .. "/bin/Release/" }
end

vim.api.nvim_create_user_command("DotnetPublish", function(args)
  vim.ui.select(M.get_csproj_files(), { prompt = "Choose csproj to publish" }, function(item, idx)
    if item == nil then
      return
    end

    vim.notify("Publishing project", vim.log.levels.INFO, { title = M.title })

    local cmd = M.get_publish_cmd(item)

    vim.fn.jobstart(cmd, {
      on_exit = function(job_id, exit_code, event_type)
        if exit_code == 0 then
          vim.notify("Publish project successfully", vim.log.levels.INFO, { title = M.title })
        else
          vim.notify("Error occur when publish project", vim.log.levels.ERROR, { title = M.title })
        end
      end,
    })
  end)
end, { desc = "dotnet publish" })

return M
