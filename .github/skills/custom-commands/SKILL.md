# Skill: Custom Commands (`lua/cmds/`)

## Purpose

The `lua/cmds/` directory holds domain-specific CLI wrappers that provide both
headless user-commands and interactive UI-driven workflows.

## File Structure

```
lua/cmds/
├── dotnet.lua     ← .NET CLI commands + DotnetManager UI
└── python.lua     ← Python-specific helpers
```

Each file is a self-contained module: `local M = {} ... return M`.

## Anatomy of a Command Module

```lua
local M = {}

M.title = "MyDomain"   -- used in vim.notify titles

-- ── helpers ─────────────────────────────────────────────────────────────────

---@param cmd string[]
---@param ctx DotnetUICtx
---@param on_complete? fun(ctx: DotnetUICtx)
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
        if on_complete then vim.schedule(function() on_complete(ctx) end) end
      else
        ctx.append("✗  Failed  (exit code " .. code .. ")")
      end
    end,
  })
end

-- ── UI command specs ─────────────────────────────────────────────────────────

M.commands = {
  {
    name    = "Greet",
    icon    = "󰊠 ",
    icon_hl = "DiagnosticHint",
    desc    = "say hello",
    action  = function(ctx)
      ctx.clear()
      ctx.append("Hello from the command module!")
    end,
  },
}

-- ── headless user commands ──────────────────────────────────────────────────

vim.api.nvim_create_user_command("MyDomainManager", function()
  require("utils.dotnet-ui").open(M.commands, { title = "My Domain" })
end, { desc = "Open My Domain Manager" })

return M
```

## Key Patterns

### Selector chaining

Actions can push sub-selections that chain into further sub-selections:

```lua
action = function(ctx)
  ctx.select({
    { _raw = "Debug",   icon = "󰃤 ", icon_hl = "DiagnosticWarn", name = "Debug" },
    { _raw = "Release", icon = "󰑊 ", icon_hl = "DiagnosticOk",   name = "Release" },
  }, {
    title     = "Configuration",
    on_select = function(item, c)
      -- item._raw is "Debug" or "Release"
      -- c is a fresh ctx — chain another selector or run_job
      select_project(c, function(proj, c2)
        run_job({ "dotnet", "build", proj, "-c", item._raw }, c2)
      end)
    end,
  })
end
```

### Auto-select when only one option

```lua
local function select_csproj(ctx, callback)
  local files = get_csproj_files()
  if #files == 0 then ctx.append("No files found."); return end
  if #files == 1 then callback(files[1], ctx); return end   -- skip UI
  ctx.select(items, { title = "Select Project", on_select = ... })
end
```

### Headless vs UI commands

- **Headless** (`DotnetBuild`, `DotnetPublish`): use `vim.ui.select` +
  `vim.notify` for simple one-shot operations.
- **UI** (`DotnetManager`): use `utils.dotnet-ui` for interactive multi-step
  workflows with streaming output.

Both styles coexist in the same file — headless commands are registered at the
bottom with `nvim_create_user_command`.

## Registering a Keymap

Add the keymap to `lua/configs/keymaps.lua`:

```lua
map("n", "<leader>dp", "<cmd>DotnetManager<CR>", { desc = "Dotnet Manager" })
```

Or add it inline in a plugin spec's `keys` field if it's tightly coupled to a
plugin.

## Conventions

- **Use `vim.fn.jobstart` with list args** (not a string) to avoid shell
  quoting issues.
- **Stream output** — set `stdout_buffered = false` and pipe chunks via
  `ctx.write(data)` for a live-updating experience.
- **Icons** — use Nerd Font icons directly in cmds/ files. Reference
  `configs.icons` only when the icon is shared across multiple modules.
- **Notifications** — use `vim.notify(msg, level, { title = M.title })` for
  headless commands.
- **Error status** — print ✓ / ✗ lines to ctx so the output highlight patterns
  in `dotnet-ui.lua` can colorize them automatically.
