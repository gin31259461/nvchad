-- Dotnet CLI commands – individual user commands + DotnetManager UI
-- SDK pinning: dotnet --list-sdks / dotnet new globaljson --sdk-version <v>

local M = {}

M.title = "Dotnet"

-- ── project helpers ───────────────────────────────────────────────────────────

---@return string[]
M.get_csproj_files = function()
  return vim.fn.glob("*.csproj", false, true)
end

---@param project string
---@return string[]
M.get_build_cmd = function(project)
  return { "dotnet", "build", project, "-c", "Debug", "-o", vim.fn.getcwd() .. "/bin/Debug/" }
end

---@param project string
---@return string[]
M.get_publish_cmd = function(project)
  return { "dotnet", "publish", project, "-p:PublishProfile=FolderProfile", "-c", "Release" }
end

-- ── UI helpers ────────────────────────────────────────────────────────────────

---Run a shell command, streaming stdout/stderr into the output panel.
---@param cmd  string[]
---@param ctx  DotnetUICtx
local function run_job(cmd, ctx)
  ctx.clear()
  ctx.append("$ " .. table.concat(cmd, " "))
  ctx.append("")

  vim.fn.jobstart(cmd, {
    stdout_buffered = false,
    stderr_buffered = false,
    on_stdout = function(_, data) ctx.write(data) end,
    on_stderr = function(_, data) ctx.write(data) end,
    on_exit = function(_, code)
      ctx.append("")
      if code == 0 then
        ctx.append("✓  Completed successfully")
      else
        ctx.append("✗  Failed  (exit code " .. code .. ")")
      end
    end,
  })
end

---Push a csproj-file selector onto the left panel, then call callback(file, ctx).
---If only one .csproj exists it is selected automatically.
---@param ctx      DotnetUICtx
---@param callback fun(file: string, ctx: DotnetUICtx)
local function select_csproj(ctx, callback)
  local files = M.get_csproj_files()
  if #files == 0 then
    ctx.clear()
    ctx.append("No .csproj files found in: " .. vim.fn.getcwd())
    return
  end
  if #files == 1 then
    callback(files[1], ctx)
    return
  end

  local ui  = require("utils.ui")
  local items = {}
  for _, f in ipairs(files) do
    table.insert(items, {
      _raw    = f,
      icon    = ui.get_file_icon(f),
      icon_hl = "DevIconCs",
      name    = f,
    })
  end

  ctx.select(items, {
    title     = "Select Project",
    on_select = function(item, c) callback(item._raw, c) end,
  })
end

-- ── command specs (consumed by DotnetManager UI) ──────────────────────────────

M.commands = {
  {
    name    = "Build",
    icon    = " ",
    icon_hl = "DiagnosticOk",
    desc    = "dotnet build",
    action  = function(ctx)
      select_csproj(ctx, function(f, c) run_job(M.get_build_cmd(f), c) end)
    end,
  },
  {
    name    = "Publish",
    icon    = "󰆦 ",
    icon_hl = "DiagnosticInfo",
    desc    = "dotnet publish",
    action  = function(ctx)
      select_csproj(ctx, function(f, c) run_job(M.get_publish_cmd(f), c) end)
    end,
  },
  {
    name    = "Restore",
    icon    = "󰁨 ",
    icon_hl = "DiagnosticWarn",
    desc    = "dotnet restore packages",
    action  = function(ctx)
      select_csproj(ctx, function(f, c)
        run_job({ "dotnet", "restore", f }, c)
      end)
    end,
  },
  {
    name    = "Run",
    icon    = "󰐊 ",
    icon_hl = "String",
    desc    = "dotnet run --project",
    action  = function(ctx)
      select_csproj(ctx, function(f, c)
        run_job({ "dotnet", "run", "--project", f }, c)
      end)
    end,
  },
  {
    name    = "Test",
    icon    = "󰙨 ",
    icon_hl = "DiagnosticHint",
    desc    = "dotnet test",
    action  = function(ctx)
      select_csproj(ctx, function(f, c)
        run_job({ "dotnet", "test", f, "-v", "minimal" }, c)
      end)
    end,
  },
  {
    name    = "Clean",
    icon    = "󰃢 ",
    icon_hl = "DiagnosticError",
    desc    = "dotnet clean",
    action  = function(ctx)
      select_csproj(ctx, function(f, c)
        run_job({ "dotnet", "clean", f }, c)
      end)
    end,
  },
  {
    name    = "Global JSON",
    icon    = "󰘦 ",
    icon_hl = "Special",
    desc    = "pin SDK version via global.json",
    action  = function(ctx)
      ctx.clear()
      if vim.fn.filereadable("global.json") == 1 then
        ctx.append("global.json already exists in " .. vim.fn.getcwd())
        return
      end

      local sdk_lines = vim.fn.systemlist("dotnet --list-sdks")
      if vim.v.shell_error ~= 0 or #sdk_lines == 0 then
        ctx.append("Failed to list .NET SDKs. Is dotnet installed?")
        return
      end

      local choices = {}
      for i = #sdk_lines, 1, -1 do
        table.insert(choices, sdk_lines[i]:gsub("[\r\n]", ""))
      end

      ctx.select(choices, {
        title     = "Select .NET SDK",
        on_select = function(choice, c)
          local version = choice:match("^(%S+)")
          if not version then
            c.append("Could not parse SDK version from: " .. choice)
            return
          end
          local cmd = "dotnet new globaljson --sdk-version " .. version
          c.clear()
          c.append("$ " .. cmd)
          c.append("")
          local out = vim.fn.system(cmd)
          if vim.v.shell_error == 0 then
            c.append("✓  Created global.json  (SDK " .. version .. ")")
          else
            c.append("✗  Error: " .. out)
          end
        end,
      })
    end,
  },
  {
    name    = "List SDKs",
    icon    = "󰈚 ",
    icon_hl = "Comment",
    desc    = "dotnet --list-sdks",
    action  = function(ctx)
      ctx.clear()
      ctx.append("$ dotnet --list-sdks")
      ctx.append("")
      local lines = vim.fn.systemlist("dotnet --list-sdks")
      if vim.v.shell_error ~= 0 then
        ctx.append("Command failed.")
      else
        ctx.write(lines)
      end
    end,
  },
  {
    name    = "List Runtimes",
    icon    = "󰈚 ",
    icon_hl = "Comment",
    desc    = "dotnet --list-runtimes",
    action  = function(ctx)
      ctx.clear()
      ctx.append("$ dotnet --list-runtimes")
      ctx.append("")
      local lines = vim.fn.systemlist("dotnet --list-runtimes")
      if vim.v.shell_error ~= 0 then
        ctx.append("Command failed.")
      else
        ctx.write(lines)
      end
    end,
  },
}

-- ── individual user commands (work without the UI) ────────────────────────────

local function notify_job(cmd, msg_start, msg_ok, msg_fail)
  vim.notify(msg_start, vim.log.levels.INFO, { title = M.title })
  vim.fn.jobstart(cmd, {
    on_exit = function(_, code)
      local ok  = code == 0
      vim.notify(
        ok and msg_ok or msg_fail,
        ok and vim.log.levels.INFO or vim.log.levels.ERROR,
        { title = M.title }
      )
    end,
  })
end

vim.api.nvim_create_user_command("DotnetBuild", function()
  vim.ui.select(M.get_csproj_files(), { prompt = "Choose project to build" }, function(f)
    if f then notify_job(M.get_build_cmd(f), "Building…", "Build succeeded", "Build failed") end
  end)
end, { desc = "Dotnet Build" })

vim.api.nvim_create_user_command("DotnetPublish", function()
  vim.ui.select(M.get_csproj_files(), { prompt = "Choose project to publish" }, function(f)
    if f then notify_job(M.get_publish_cmd(f), "Publishing…", "Publish succeeded", "Publish failed") end
  end)
end, { desc = "Dotnet Publish" })

vim.api.nvim_create_user_command("DotnetGlobalJson", function()
  if vim.fn.filereadable("global.json") == 1 then
    vim.notify("global.json already exists.", vim.log.levels.WARN, { title = M.title })
    return
  end
  local sdk_lines = vim.fn.systemlist("dotnet --list-sdks")
  if vim.v.shell_error ~= 0 or #sdk_lines == 0 then
    vim.notify("Failed to retrieve SDK list.", vim.log.levels.ERROR, { title = M.title })
    return
  end
  local choices = {}
  for i = #sdk_lines, 1, -1 do
    table.insert(choices, sdk_lines[i]:gsub("[\r\n]", ""))
  end
  vim.ui.select(choices, { prompt = "Select .NET SDK version:" }, function(choice)
    if not choice then return end
    local version = choice:match("^(%S+)")
    if version then
      local out = vim.fn.system("dotnet new globaljson --sdk-version " .. version)
      local ok  = vim.v.shell_error == 0
      vim.notify(
        ok and "Created global.json (SDK " .. version .. ")" or "Error: " .. out,
        ok and vim.log.levels.INFO or vim.log.levels.ERROR,
        { title = M.title }
      )
    end
  end)
end, { desc = "Dotnet global.json – pin SDK version" })

vim.api.nvim_create_user_command("DotnetManager", function()
  require("utils.dotnet_ui").open(M.commands, { title = "Dotnet Manager" })
end, { desc = "Open Dotnet Manager UI" })

return M
