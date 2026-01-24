-- use the specified sdk:
-- dotnet --list-sdks
-- dotnet new globaljson --sdk-version <version>

local M = {}

M.title = "Dotnet"

---@return string[]
M.get_csproj_files = function()
  return vim.fn.glob("*.csproj", false, true)
end

M.get_publish_cmd = function(project)
  return { "dotnet", "publish", project, "-p:PublishProfile=FolderProfile", "-c", "Release" }
end

---@param project? string
M.get_build_cmd = function(project)
  return { "dotnet", "build", project or "", "-c", "Debug", "-o", vim.fn.getcwd() .. "/bin/Debug/" }
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
end, { desc = "Dotnet Publish" })

vim.api.nvim_create_user_command("DotnetBuild", function(args)
  vim.ui.select(M.get_csproj_files(), { prompt = "Choose csproj to publish" }, function(item, idx)
    if item == nil then
      return
    end

    vim.notify("Building project", vim.log.levels.INFO, { title = M.title })

    local cmd = M.get_build_cmd(item)

    vim.fn.jobstart(cmd, {
      on_exit = function(job_id, exit_code, event_type)
        if exit_code == 0 then
          vim.notify("Build project successfully", vim.log.levels.INFO, { title = M.title })
        else
          vim.notify("Error occur when Build project", vim.log.levels.ERROR, { title = M.title })
        end
      end,
    })
  end)
end, { desc = "Dotnet Build" })

return M
