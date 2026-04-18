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
---@param config? string  "Debug" or "Release" (default "Debug")
---@return string[]
M.get_build_cmd = function(project, config)
  config = config or "Debug"
  return { "dotnet", "build", project, "-c", config, "-o", vim.fn.getcwd() .. "/bin/" .. config .. "/" }
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
---@param on_complete? fun(ctx: DotnetUICtx)  called on exit-code 0
local function run_job(cmd, ctx, on_complete)
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
        if on_complete then
          vim.schedule(function() on_complete(ctx) end)
        end
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

-- ── template helpers ──────────────────────────────────────────────────────────

---Parse the tabular output of `dotnet new list` into template records.
---@param lines string[]
---@return {name: string, short_name: string}[]
local function parse_dotnet_templates(lines)
  local templates = {}
  local in_data = false
  for _, line in ipairs(lines) do
    if line:match("^%-%-%-%-") then
      in_data = true
    elseif in_data and line:match("%S") then
      local parts = vim.split(vim.trim(line), "%s%s+")
      if #parts >= 2 then
        table.insert(templates, {
          name       = vim.trim(parts[1]),
          short_name = vim.trim(parts[2]),
        })
      end
    end
  end
  return templates
end

---Read TargetFramework from a .csproj, copy the publish-profile template, and
---fill in the correct framework value.
---@param project_dir string
---@param ctx         DotnetUICtx
local function configure_publish_profile(project_dir, ctx)
  -- locate the .csproj inside the new project folder
  local csproj_files = vim.fn.glob(project_dir .. "/*.csproj", false, true)
  if #csproj_files == 0 then
    ctx.append("⚠  No .csproj found in " .. project_dir)
    return
  end

  local csproj_content = table.concat(vim.fn.readfile(csproj_files[1]), "\n")
  local target_fw = csproj_content:match("<TargetFramework>(.+)</TargetFramework>")
  if not target_fw then
    ctx.append("⚠  Could not detect TargetFramework from " .. csproj_files[1])
    return
  end

  local template_path = vim.fn.stdpath("config") .. "/lua/configs/lsp/template/dotnet.csproj"
  if vim.fn.filereadable(template_path) ~= 1 then
    ctx.append("⚠  Publish-profile template not found: " .. template_path)
    return
  end

  local template_lines = vim.fn.readfile(template_path)
  for i, line in ipairs(template_lines) do
    if line:find("TargetFramework") and line:find("netx%.x") then
      template_lines[i] = "    <TargetFramework>" .. target_fw .. "</TargetFramework>"
    end
  end

  local profile_dir  = project_dir .. "/Properties/PublishProfiles"
  vim.fn.mkdir(profile_dir, "p")
  local profile_path = profile_dir .. "/FolderProfile.pubxml"
  vim.fn.writefile(template_lines, profile_path)

  ctx.append("")
  ctx.append("✓  Created publish profile: " .. profile_path)
  ctx.append("   TargetFramework: " .. target_fw)
end

-- ── command specs (consumed by DotnetManager UI) ──────────────────────────────

M.commands = {
  {
    name    = "Build",
    icon    = "󰒓 ",
    icon_hl = "DiagnosticOk",
    desc    = "dotnet build",
    action  = function(ctx)
      ctx.select({
        { _raw = "Debug",   icon = "󰃤 ", icon_hl = "DiagnosticWarn", name = "Debug" },
        { _raw = "Release", icon = "󰑊 ", icon_hl = "DiagnosticOk",   name = "Release" },
      }, {
        title     = "Build Configuration",
        on_select = function(item, c)
          local config = item._raw
          select_csproj(c, function(f, c2) run_job(M.get_build_cmd(f, config), c2) end)
        end,
      })
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
        table.insert(choices, (sdk_lines[i]:gsub("[\r\n]", "")))
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
  {
    name    = "New Project",
    icon    = "󰝒 ",
    icon_hl = "DiagnosticInfo",
    desc    = "dotnet new",
    action  = function(ctx)
      ctx.clear()
      ctx.append("$ dotnet new list")
      ctx.append("")

      local raw = vim.fn.systemlist("dotnet new list")
      if vim.v.shell_error ~= 0 then
        ctx.append("Failed to list templates. Is dotnet installed?")
        return
      end

      local templates = parse_dotnet_templates(raw)
      if #templates == 0 then
        ctx.append("No templates found.")
        return
      end

      local items = {}
      for _, t in ipairs(templates) do
        table.insert(items, {
          _raw    = t,
          icon    = "󰈚 ",
          icon_hl = "Special",
          name    = t.name .. "  (" .. t.short_name .. ")",
        })
      end

      ctx.select(items, {
        title     = "Select Template",
        on_select = function(item, c)
          local tpl = item._raw
          vim.cmd("stopinsert")
          vim.ui.input({ prompt = "Project name: " }, function(name)
            if not name or name == "" then return end
            vim.schedule(function()
              run_job(
                { "dotnet", "new", tpl.short_name, "-n", name, "-o", name },
                c,
                function(ctx2)
                  -- ask whether to set up publish profile from template
                  vim.schedule(function()
                    vim.ui.select({ "Yes", "No" }, {
                      prompt = "Configure publish profile (.pubxml) from custom template?",
                    }, function(choice)
                      if choice == "Yes" then
                        vim.schedule(function()
                          configure_publish_profile(name, ctx2)
                        end)
                      end
                    end)
                  end)
                end
              )
            end)
          end)
        end,
      })
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
    table.insert(choices, (sdk_lines[i]:gsub("[\r\n]", "")))
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
  require("utils.dotnet-ui").open(M.commands, { title = "Dotnet Manager" })
end, { desc = "Open Dotnet Manager UI" })

return M
