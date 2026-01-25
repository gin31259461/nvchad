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

vim.api.nvim_create_user_command("DotnetGlobalJson", function()
  -- 1. Check if global.json exists in the current working directory
  if vim.fn.filereadable("global.json") == 1 then
    vim.notify("global.json already exists. Skipping operation.", vim.log.levels.WARN)
    return
  end

  -- 2. Fetch installed SDKs using the dotnet CLI
  -- Output format example: "8.0.100 [/usr/share/dotnet/sdk]"
  local sdk_output = vim.fn.systemlist("dotnet --list-sdks")

  -- Handle case where dotnet command fails or no SDKs are returned
  if vim.v.shell_error ~= 0 or #sdk_output == 0 then
    vim.notify("Failed to retrieve .NET SDK list. Is dotnet installed?", vim.log.levels.ERROR)
    return
  end

  -- 3. Prepare data for selection
  -- We reverse the list to show the latest versions first (optional preference)
  local choices = {}
  for i = #sdk_output, 1, -1 do
    -- Remove Carriage Return (^M) and extra whitespace
    local line = sdk_output[i]:gsub("[\r\n]", "")
    table.insert(choices, line)
  end

  -- 4. Prompt the user to select a version
  vim.ui.select(choices, {
    prompt = "Select .NET SDK Version:",
    format_item = function(item)
      -- Display the full line so the user can see the path if needed
      return item
    end,
  }, function(choice)
    -- If the user cancels the selection (e.g., presses Esc), choice will be nil
    if not choice then
      return
    end

    -- Extract just the version number (the first part of the string)
    -- e.g., "8.0.100" from "8.0.100 [/path/to/sdk]"
    local version = choice:match("^(%S+)")

    if version then
      -- 5. Execute the creation command
      local cmd = string.format("dotnet new globaljson --sdk-version %s", version)
      local output = vim.fn.system(cmd)

      if vim.v.shell_error == 0 then
        vim.notify("Successfully created global.json with SDK: " .. version, vim.log.levels.INFO)
      else
        vim.notify("Error creating global.json: " .. output, vim.log.levels.ERROR)
      end
    end
  end)
end, { desc = "Dotnet New global.json (for .NET SDK Version Control)" })

return M
