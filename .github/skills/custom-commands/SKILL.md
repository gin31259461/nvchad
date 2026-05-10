---
name: custom-commands
description: "Create domain-specific CLI commands with optional interactive UIs."
---

# Skill: Custom Commands (`lua/cmds/`)

## Purpose

The `lua/cmds/` directory holds domain-specific CLI wrappers that provide both
headless user-commands and interactive UI-driven workflows.

## File Structure

```
lua/cmds/
├── python.lua     ← Python venv helpers + PyrightReCreateStub command
└── system.lua     ← Platform-specific system commands (Windows: ClearShada)
```

Each file is a self-contained module: `local M = {} ... return M`.
All files in `lua/cmds/` are **auto-loaded** at startup by a `fs.scandir` loop
in `init.lua` — no manual registration is needed when adding a new file.

## Anatomy of a Command Module

```lua
local M = {}

M.title = "MyDomain"   -- used in vim.notify titles

-- ── helpers ─────────────────────────────────────────────────────────────────

---@param cmd string[]
---@param on_complete? fun(exit_code: number)
local function run_job(cmd, on_complete)
  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      for _, line in ipairs(data) do
        if line ~= "" then vim.notify(line, vim.log.levels.INFO, { title = M.title }) end
      end
    end,
    on_exit = function(_, code)
      if on_complete then on_complete(code) end
    end,
  })
end

-- ── user commands ────────────────────────────────────────────────────────────

vim.api.nvim_create_user_command("MyDomainAction", function()
  local items = { "Option A", "Option B" }
  vim.ui.select(items, { prompt = "Choose an action:" }, function(item)
    if not item then return end
    run_job({ "my-cli", item }, function(code)
      if code == 0 then
        vim.notify("Done!", vim.log.levels.INFO, { title = M.title })
      else
        vim.notify("Failed (exit " .. code .. ")", vim.log.levels.ERROR, { title = M.title })
      end
    end)
  end)
end, { desc = "Run my domain action" })

return M
```

## Key Patterns

### Platform guards

Use `utils.os` helpers for platform-specific commands:

```lua
local os_utils = require("utils.os")

if not os_utils.is_win() then
  return   -- early exit: command only makes sense on Windows
end

vim.api.nvim_create_user_command("WinOnlyCmd", function()
  -- ...
end, { desc = "Windows-only action" })
```

### Auto-select when only one option

```lua
local items = get_available_items()
if #items == 0 then vim.notify("No items found.", vim.log.levels.WARN); return end
if #items == 1 then process(items[1]); return end   -- skip UI when obvious
vim.ui.select(items, { prompt = "Select:" }, process)
```

### Headless commands with vim.ui.select

Use `vim.ui.select` + `vim.notify` for simple one-shot interactive operations:

```lua
vim.api.nvim_create_user_command("MyCmd", function()
  vim.ui.select(get_choices(), { prompt = "Choose:" }, function(item)
    if not item then return end
    -- run action with item
  end)
end, { desc = "Description shown in which-key" })
```

## Registering a Keymap

Add the keymap to `lua/config/keymaps.lua`:

```lua
map("n", "<leader>dp", "<cmd>DotnetManager<CR>", { desc = "Dotnet Manager" })
```

Or add it inline in a plugin spec's `keys` field if it's tightly coupled to a
plugin.

## Conventions

- **Use `vim.fn.jobstart` with list args** (not a string) to avoid shell quoting
  issues.
- **Stream output** — set `stdout_buffered = false` and handle chunks in
  `on_stdout` for a live-updating experience.
- **Icons** — use Nerd Font icons directly in `cmds/` files. Reference
  `config.icons` only when the icon is shared across multiple modules.
- **Notifications** — use `vim.notify(msg, level, { title = M.title })`.
- **Platform guards** — use `require("utils.os").is_win()` for OS-specific
  logic; prefer an early `return` over deeply nested conditionals.
- **No dotnet commands here** — `.NET` CLI commands are owned by the
  `Orbit-Lua/dotnet-cli.nvim` plugin. Extend via `opts`, not `cmds/`.
