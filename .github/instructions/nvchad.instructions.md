# NvChad Custom Configuration — Repository Guidelines

> This document is the authoritative reference for AI assistants, contributors, and
> future sessions working on this Neovim configuration. Read it before making any
> changes.

## 1. Overview

This is a **NvChad v2.5** custom configuration for Neovim (≥ 0.12). It provides a
full-featured IDE experience for **C# / .NET**, **Python**, **TypeScript**,
**Lua**, **Go**, **C/C++**, and web technologies, with custom UI components,
debugger integration, and project-management tooling.

| Layer        | Location          | Purpose                                         |
| ------------ | ----------------- | ----------------------------------------------- |
| Entry point  | `init.lua`        | Bootstrap lazy.nvim, load options & plugins      |
| Options      | `lua/configs/`    | Neovim settings, keymaps, packages, formatters   |
| Plugins      | `lua/plugins/`    | lazy.nvim specs grouped by concern               |
| LSP servers  | `lua/plugins/lsp/servers/` | Per-language server configs              |
| Debugger     | `lua/plugins/debugger/`    | DAP adapters & UI                        |
| Utilities    | `lua/utils/`      | Shared helpers (LSP, FS, UI, shell, statusline)  |
| Commands     | `lua/cmds/`       | Domain-specific CLI wrappers (.NET, Python)      |
| Types        | `lua/types/`      | `---@meta` type-annotation files                 |
| Theme        | `lua/chadrc.lua`  | NvChad theme, statusline, highlight overrides    |

## 2. Code Style

### Formatter — StyLua

All Lua files must conform to `.stylua.toml`:

```toml
indent_type = "Spaces"
indent_width = 2
column_width = 120
[sort_requires]
enabled = true
```

**Key rules:**

- **2-space indent**, spaces only.
- **120-column line limit.**
- Requires are auto-sorted — do not fight the sort order.
- Run `stylua lua/` from the repo root to format.

### Naming

| Thing            | Convention             | Example                          |
| ---------------- | ---------------------- | -------------------------------- |
| Modules          | `snake_case`           | `utils.fs`, `cmds.dotnet`        |
| Functions        | `snake_case`           | `get_csproj_files()`             |
| Local variables  | `snake_case`           | `local list_h`                   |
| Type annotations | `PascalCase`           | `Lsp.Config.Spec`, `DotnetUICtx` |
| Files            | `snake_case` or kebab  | `dotnet-ui.lua`, `lua_ls.lua`    |
| Constants        | `UPPER_SNAKE`          | `OUT_HL_PATTERNS`                |

### Module Export Pattern

Every module returns a table `M`:

```lua
local M = {}

-- ... implementation ...

return M
```

### Type Annotations

Use Neovim-style LuaLS annotations liberally:

```lua
---@param project string
---@param config? string  "Debug" or "Release" (default "Debug")
---@return string[]
M.get_build_cmd = function(project, config) ... end
```

For complex shared types, create `---@meta` files under `lua/types/`.

### Comments

- Use comments only when the *why* is non-obvious. Do not comment trivial code.
- Section headers use box-drawing separators:

```lua
-- ── section name ──────────────────────────────────────────────────────────
```

## 3. Architecture Rules

### Plugin Specs (`lua/plugins/`)

- Every spec uses **lazy.nvim** format: `{ "author/repo", opts = {}, ... }`.
- Always lazy-load via `event`, `cmd`, `ft`, or `keys` — avoid `lazy = false`
  unless the plugin must be available at startup (e.g., NvChad UI, snacks).
- Group specs by concern: `ui.lua`, `coding.lua`, `navigation.lua`,
  `formatter.lua`, `linter.lua`, `misc.lua`.
- Sub-directories (`lsp/`, `debugger/`, `ui/`, `db/`) hold multi-file setups.

### LSP Server Configuration (`lua/plugins/lsp/servers/`)

Each file returns `---@type Lsp.Server.Module`:

```lua
---@type Lsp.Server.Module
return {
  servers = {
    server_name = {
      settings = { ... },
      keys = { ... },            -- LazyKeysSpec[]
      on_attach = function(client, bufnr) ... end,
    },
  },
  setup = {
    server_name = function() ... end,  -- custom setup (e.g., roslyn.nvim)
  },
}
```

- **Base config** lives in `servers/base.lua` (diagnostics, capabilities,
  `on_init`). All servers inherit it.
- `config.lua` merges base + all server modules automatically — just add a new
  file and register it in `config.lua`'s `server_modules` list.
- Server names must match the key used by `lspconfig` / Mason.
- Register the Mason package name in `lua/configs/packages.lua` under
  `pkgs_with_lsp_setup`.

### Custom Commands (`lua/cmds/`)

- One file per domain (e.g., `dotnet.lua`, `python.lua`).
- Expose helpers as module functions for reuse (debugger, UI).
- Register `vim.api.nvim_create_user_command()` at the bottom of the file.
- UI-driven commands use `utils.dotnet-ui` for the panel interface.

### Utilities (`lua/utils/`)

- `utils/init.lua` is the barrel file — it re-exports all submodules and
  proxies `lazy.core.util`.
- Add new util files and register them in `utils/init.lua`.
- Utilities must be stateless and side-effect-free at require time.
  `utils.setup()` is the one-time init entry point.

### Keymaps

- **General keymaps** → `lua/configs/keymaps.lua` (deferred via `vim.schedule`).
- **LSP keymaps** → `lua/plugins/lsp/keymaps.lua` (capability-aware, dynamic).
- **Plugin keymaps** → inline in each plugin spec's `keys` field.
- **DAP keymaps** → `lua/plugins/debugger/init.lua`.
- Use `<leader>` prefix for user commands. Current prefix assignments:
  - `<leader>f` — find / format
  - `<leader>b` — buffer
  - `<leader>c` — code (LSP actions)
  - `<leader>d` — debug / dotnet
  - `<leader>s` — search
  - `<leader>g` — git
  - `<leader>t` — tab / theme
  - `<leader>w` — which-key
  - `<leader>m` — markdown

## 4. Dotnet-UI Component (`lua/utils/dotnet-ui.lua`)

A custom two-panel Telescope-style picker used by the Dotnet Manager.

### Public API

```lua
require("utils.dotnet-ui").open(commands, { title = "Dotnet Manager" })
```

### Command Spec

```lua
---@class DotnetUICommand
---@field name     string
---@field icon     string          -- Nerd Font icon
---@field icon_hl? string          -- highlight group (default "String")
---@field desc?    string          -- used for fuzzy filtering
---@field action   fun(ctx: DotnetUICtx)
```

### Context API (passed to actions)

| Method                     | Description                              |
| -------------------------- | ---------------------------------------- |
| `ctx.write(lines)`         | Append string or `string[]` to output    |
| `ctx.clear()`              | Clear the output panel                   |
| `ctx.append(line)`         | Append a single line                     |
| `ctx.select(items, opts)`  | Push a sub-selection list (filterable)   |

`ctx.select` options: `{ title?, on_select: fun(item, ctx), on_cancel?: fun() }`

### UI Behaviour

- **Left panel:** prompt input (top) + scrollable item list (below).
- **Right panel:** output with pattern-based highlighting.
- `Tab` toggles focus to output (title shows "(focused)", cursorline on).
- `Esc` / `q` in output returns focus to input — does **not** close the UI.
- `Esc` in input cancels sub-selection or closes the UI.
- `C-j` / `C-k` navigate the list in both insert and normal mode.
- List selection **wraps around** (bottom → top, top → bottom).
- Sub-selection menus are **filterable** — typing filters the sub-items.
- Input text is saved / restored when entering / leaving sub-selections.

### Output Highlight Patterns

Lines matching these patterns get line-level highlights:

| Pattern            | Highlight Group    |
| ------------------ | ------------------ |
| `^$ `              | `Comment`          |
| `✓`                | `DiagnosticOk`     |
| `✗`                | `DiagnosticError`  |
| `Build succeeded`  | `DiagnosticOk`     |
| `Build FAILED`     | `DiagnosticError`  |
| `[Ww]arning`       | `DiagnosticWarn`   |
| `[Ee]rror`         | `DiagnosticError`  |
| `Passed!`          | `DiagnosticOk`     |
| `Failed!`          | `DiagnosticError`  |

## 5. Adding a New Language

### Checklist

1. **Treesitter parser** — add to `configs/packages.lua` →
   `treesitter_ensure_installed`.
2. **LSP server** — add to `configs/packages.lua` → `pkgs_with_lsp_setup`
   (key = lspconfig name, value = Mason package name).
3. **Server config** — create `lua/plugins/lsp/servers/<lang>.lua` returning
   `---@type Lsp.Server.Module`, then add it to the `server_modules` list in
   `lua/plugins/lsp/config.lua`.
4. **Formatter** — add to `lua/configs/formatter/init.lua` (conform.nvim format).
5. **Linter** — add to `lua/configs/linter/init.lua` (nvim-lint format).
6. **Debugger** (optional) — add adapter in `lua/plugins/debugger/<lang>.lua`,
   register in `lua/plugins/debugger/config.lua`.

## 6. Dependency Flow

```
init.lua
  │
  ├─ configs/options.lua        (vim.opt settings)
  ├─ configs/packages.lua       (LSP / Mason / Treesitter package lists)
  ├─ configs/keymaps.lua        (general keymaps — deferred)
  │
  ├─ plugins/**                 (lazy.nvim specs)
  │   ├─ lsp/config.lua         (merges base.lua + servers/*.lua)
  │   ├─ lsp/setup.lua          (iterates config, calls lspconfig)
  │   └─ debugger/config.lua    (loads DAP adapters)
  │
  ├─ utils/**                   (shared helpers, imported anywhere)
  │   └─ init.lua               (barrel, proxies lazy.core.util)
  │
  └─ cmds/**                    (domain commands, used by plugins & debugger)
```

## 7. Testing & Validation

- **Syntax check:** `luac -p lua/**/*.lua` — must pass with zero errors.
- **Format check:** `stylua --check lua/` — must pass.
- **Runtime validation:** Open Neovim, run `:checkhealth`, verify no errors in
  Mason, LSP, Treesitter, or DAP sections.
- **Lazy profile:** `:Lazy profile` — startup should stay under 100 ms.

## 8. Important Conventions

1. **Never `require()` at module top-level if the target is a plugin** — use
   lazy-loading or wrap in a function / `vim.schedule`.
2. **Avoid `vim.cmd` for things the Lua API can do** — prefer
   `vim.api`, `vim.keymap.set`, `vim.diagnostic`, etc.
3. **Use `pcall` around optional dependencies** — the config must not crash if a
   plugin is disabled.
4. **Icons come from `configs.icons`** — do not hardcode icon strings in plugin
   specs; reference the central table instead (Nerd Font icons are acceptable
   in cmds/ and utils/ UI code).
5. **Cross-platform paths** — use `vim.fn.stdpath()`, `vim.uv.fs_stat()`, and
   forward slashes. The config runs on Linux, macOS, and Windows (MSYS2).
6. **Semantic tokens are disabled globally** via `on_init` in
   `servers/base.lua`. Do not re-enable per-server without reason.
7. **No commits should include secrets** — `.gitignore` already excludes
   sensitive paths; keep it that way.
