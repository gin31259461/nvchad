# NvChad Custom Configuration — Repository Guidelines

> This document is the authoritative reference for AI assistants, contributors,
> and future sessions working on this Neovim configuration. Read it before
> making any changes.

## 1. Overview

This is a **NvChad v2.5** custom configuration for Neovim (≥ 0.12). It provides
a full-featured IDE experience for **C# / .NET**, **Python**, **TypeScript**,
**Lua**, **Go**, **C/C++**, **Bash**, **PowerShell**, **SQL/Prisma**, **Docker**,
and web technologies (HTML, CSS, JSON, TOML, XML, Markdown), with custom UI
components, AI coding assistance (Copilot, OpenCode), debugger integration, and
project-management tooling.

| Layer       | Location                   | Purpose                                         |
| ----------- | -------------------------- | ----------------------------------------------- |
| Entry point | `init.lua`                 | Bootstrap lazy.nvim, load options & plugins     |
| Options     | `lua/config/`              | Neovim settings, keymaps, packages, formatters  |
| Plugins     | `lua/plugins/`             | lazy.nvim specs grouped by concern              |
| LSP servers | `lua/plugins/lsp/servers/` | Per-language server configs                     |
| Debugger    | `lua/plugins/debugger/`    | DAP adapters & UI                               |
| Utilities   | `lua/utils/`               | Shared helpers (LSP, FS, UI, shell, statusline, cmp, hl, str, table) |
| Commands    | `lua/cmds/`                | Domain-specific CLI wrappers (Python, system)   |
| Types       | `lua/types/`               | `---@meta` type-annotation files                |
| Theme       | `lua/chadrc.lua`           | NvChad theme, statusline, highlight overrides   |

## 2. Code Style

### Formatter — StyLua

All Lua files must conform to `.stylua.toml`:

```toml
column_width = 100
line_endings = "Unix"
indent_type = "Spaces"
indent_width = 2
quote_style = "AutoPreferDouble"
call_parentheses = "Always"
```

**Key rules:**

- **2-space indent**, spaces only.
- **100-column line limit.**
- Double quotes preferred (`AutoPreferDouble`).
- Run `stylua lua/` from the repo root to format.

### Naming

| Thing            | Convention            | Example                          |
| ---------------- | --------------------- | -------------------------------- |
| Modules          | `snake_case`          | `utils.fs`, `utils.lsp`          |
| Functions        | `snake_case`          | `get_csproj_files()`             |
| Local variables  | `snake_case`          | `local list_h`                   |
| Type annotations | `PascalCase`          | `Lsp.Config.Spec`, `DotnetUICtx` |
| Files            | `snake_case` or kebab | `lua_ls.lua`, `dotnet.lua`       |
| Constants        | `UPPER_SNAKE`         | `OUT_HL_PATTERNS`                |

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

- Use comments only when the _why_ is non-obvious. Do not comment trivial code.
- Section headers use box-drawing separators:

```lua
-- ── section name ──────────────────────────────────────────────────────────
```

## 3. Architecture Rules

### Plugin Specs (`lua/plugins/`)

- Every spec uses **lazy.nvim** format: `{ "author/repo", opts = {}, ... }`.
- Always lazy-load via `event`, `cmd`, `ft`, or `keys` — avoid `lazy = false`
  unless the plugin must be available at startup (e.g., NvChad UI, snacks).
- Group specs by concern: `ai.lua`, `coding.lua`, `db.lua`, `formatter.lua`,
  `linter.lua`, `misc.lua`, `navigation.lua`, `ui.lua`.
- The root `plugins/init.lua` holds small standalone specs (gitsigns,
  markdown-preview.nvim, which-key).
- Sub-directories (`lsp/`, `debugger/`, `ui/`) hold multi-file setups.
  `ui/` is composed of `nvchad.lua`, `snacks.lua`, `noice.lua`, `trouble.lua`,
  and `dotnet.lua`, all gathered by `plugins/ui.lua`.

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
- Register the Mason package name in `lua/config/packages.lua` under
  `pkgs_with_lsp_setup`.

### Custom Commands (`lua/cmds/`)

- One file per domain (e.g., `python.lua`, `system.lua`).
- Expose helpers as module functions for reuse (debugger, LSP).
- Register `vim.api.nvim_create_user_command()` at the bottom of the file.
- All files in `lua/cmds/` are auto-loaded by `init.lua` at startup via a
  `fs.scandir` loop — no manual registration needed.
- **Dotnet commands** (`DotnetManager`, `DotnetBuild`, `DotnetPublish`,
  `DotnetGlobalJson`) are provided by the external
  `Orbit-Lua/dotnet-cli.nvim` plugin (spec: `lua/plugins/ui/dotnet.lua`).
  Do **not** create a custom `cmds/dotnet.lua`.

### Utilities (`lua/utils/`)

- `utils/init.lua` is the barrel file — it re-exports all submodules and proxies
  `lazy.core.util`.
- Add new util files and register them in `utils/init.lua`.
- Utilities must be stateless and side-effect-free at require time.
  `utils.setup()` is the one-time init entry point.

### Keymaps

- **General keymaps** → `lua/config/keymaps.lua` (deferred via `vim.schedule`).
- **LSP keymaps** → `lua/plugins/lsp/keymaps.lua` (capability-aware, dynamic).
- **Plugin keymaps** → inline in each plugin spec's `keys` field.
- **DAP keymaps** → `lua/plugins/debugger/init.lua`.
- Use `<leader>` prefix for user commands. Current prefix assignments:
  - `<leader>f` — find / format
  - `<leader>b` — buffer
  - `<leader>c` — code (LSP actions)
  - `<leader>d` — debug / dotnet (`dp` = DotnetManager; rest = DAP)
  - `<leader>s` — search / picker
  - `<leader>g` — git
  - `<leader>t` — trouble / todos (`th` = NvChad themes)
  - `<leader>w` — which-key
  - `<leader>h` — terminal new horizontal term
  - `<leader>v` — terminal new vertical term
  - `<leader>m` — markdown
  - `<leader>a` — harpoon add
  - `<leader>e` — NvimTree focus
  - `<leader>x` — close buffer
  - `<leader>/` — toggle comment
  - `<leader>q` — record macro
  - `<leader>D` — Snacks dashboard
  - `<leader>n` — notification history
  - `<leader>cd` — cd to project root

## 4. Dotnet Plugin (`lua/plugins/ui/dotnet.lua`)

.NET support is provided by the external **`Orbit-Lua/dotnet-cli.nvim`** plugin
(UI powered by `Orbit-Lua/comet.nvim`). The plugin is lazy-loaded on `.cs`
files or when one of its commands is invoked.

### Plugin Spec

```lua
-- lua/plugins/ui/dotnet.lua
{
  "Orbit-Lua/dotnet-cli.nvim",
  dependencies = { "Orbit-Lua/comet.nvim" },
  cmd = { "DotnetManager", "DotnetBuild", "DotnetPublish", "DotnetGlobalJson" },
  ft = "cs",
  opts = {},
}
```

### Available Commands

| Command             | Description                             |
| ------------------- | --------------------------------------- |
| `DotnetManager`     | Opens the interactive .NET manager UI   |
| `DotnetBuild`       | Runs `dotnet build` on the project      |
| `DotnetPublish`     | Runs `dotnet publish` on the project    |
| `DotnetGlobalJson`  | Manages `global.json` SDK pinning       |

### Keymap

`<leader>dp` → `<cmd>DotnetManager<CR>` (defined in `lua/config/keymaps.lua`).

### Extending / Configuring

Pass options to the plugin via the `opts` table in `lua/plugins/ui/dotnet.lua`.
Refer to the [dotnet-cli.nvim documentation](https://github.com/Orbit-Lua/dotnet-cli.nvim)
for the full options reference.

Do **not** add a `lua/cmds/dotnet.lua` — all .NET command logic belongs to
the plugin.

## 5. Adding a New Language

### Checklist

1. **Treesitter parser** — add to `config/packages.lua` →
   `treesitter_ensure_installed`.
2. **LSP server** — add to `config/packages.lua` → local `pkgs_with_lsp_setup` (key =
   lspconfig name, value = Mason package name). Companion tools go in `pkgs_only`.
3. **Server config** — create `lua/plugins/lsp/servers/<lang>.lua` returning
   `---@type Lsp.Server.Module`, then add it to the `server_modules` list in
   `lua/plugins/lsp/config.lua`.
4. **Formatter** — add to `lua/config/formatter/init.lua` (conform.nvim
   format).
5. **Linter** — add to `lua/config/linter/init.lua` (nvim-lint format).
6. **Debugger** (optional) — add adapter in `lua/plugins/debugger/<lang>.lua`,
   register in `lua/plugins/debugger/config.lua`.

## 6. Dependency Flow

```
init.lua
  │
  ├─ config/options.lua         (vim.opt settings)
  ├─ config/autocmds.lua        (DiagnosticChanged redraw fix)
  ├─ config/filetypes.lua       (vim.filetype.add registrations)
  ├─ config/packages.lua        (LSP / Mason / Treesitter package lists)
  ├─ config/keymaps.lua         (general keymaps — deferred)
  │
  ├─ plugins/**                 (lazy.nvim specs)
  │   ├─ init.lua               (gitsigns, markdown-preview, which-key)
  │   ├─ ai.lua                 (copilot, opencode)
  │   ├─ coding.lua             (treesitter, cmp, snippets)
  │   ├─ db.lua                 (database/SQL tooling)
  │   ├─ navigation.lua         (nvim-tree, telescope, harpoon)
  │   ├─ ui.lua                 (gathers ui/ submodules)
  │   ├─ lsp/config.lua         (merges base.lua + servers/*.lua)
  │   ├─ lsp/setup.lua          (iterates config, calls lspconfig)
  │   ├─ lsp/diagnostics.lua    (configure signs/virtual-text + filter middleware)
  │   ├─ lsp/features.lua       (inlay hints + code lens activation)
  │   └─ debugger/config.lua    (loads DAP adapters)
  │
  ├─ utils/**                   (shared helpers, imported anywhere)
  │   └─ init.lua               (barrel, proxies lazy.core.util)
  │
  └─ cmds/**                    (auto-loaded domain commands)
      ├─ python.lua             (Python venv helpers + PyrightReCreateStub)
      └─ system.lua             (Windows-only ClearShada command)
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
2. **Avoid `vim.cmd` for things the Lua API can do** — prefer `vim.api`,
   `vim.keymap.set`, `vim.diagnostic`, etc.
3. **Use `pcall` around optional dependencies** — the config must not crash if a
   plugin is disabled.
4. **Icons come from `config.icons`** — do not hardcode icon strings in plugin
   specs; reference the central table instead (Nerd Font icons are acceptable in
   cmds/ and utils/ UI code).
5. **Cross-platform paths** — use `vim.fn.stdpath()`, `vim.uv.fs_stat()`, and
   forward slashes. The config runs on Linux, macOS, and Windows (MSYS2).
6. **Semantic tokens are disabled globally** via `on_init` in
   `servers/base.lua`. Do not re-enable per-server without reason.
7. **No commits should include secrets** — `.gitignore` already excludes
   sensitive paths; keep it that way.

## 9. Design Principles — SoC, Low Coupling, Dependency Injection

### Separation of Concerns (SoC)

Each file or module has exactly **one responsibility**. Changes to one concern
must not ripple into unrelated modules.

| Concern              | Owner                                   |
| -------------------- | --------------------------------------- |
| Editor options       | `config/options.lua`                    |
| Keymap registration  | `config/keymaps.lua`, `plugins/*/keys`  |
| LSP capabilities     | `plugins/lsp/servers/base.lua`          |
| Server-specific opts | `plugins/lsp/servers/<lang>.lua`        |
| Formatter config     | `config/formatter/init.lua`             |
| Linter config        | `config/linter/init.lua`                |
| DAP adapter/config   | `plugins/debugger/<lang>.lua`           |
| Shared helpers       | `lua/utils/<concern>.lua`               |
| Domain commands      | `lua/cmds/<domain>.lua`                 |

**Rule:** TypeScript-specific logic (e.g. copying JS settings into vtsls) belongs
in `servers/typescript.lua`, not in the generic `setup.lua`.

### Low Coupling

Modules must not directly depend on **plugin internals** or reach into other
modules' private state.

**Required practices:**

1. **Never `require()` a plugin at module top-level.** Plugins are loaded
   asynchronously by lazy.nvim. A top-level require will run at spec-collection
   time, before the plugin is available.

   ```lua
   -- ✗ bad — runs at file load time; crashes if plugin not installed
   local snacks = require("snacks")

   -- ✓ good — deferred to call time; plugin is already loaded
   local function foo()
     require("snacks").do_thing()
   end
   ```

2. **Wrap `opts` in a function when it closes over plugin modules.**
   lazy.nvim calls `opts = function()` after the plugin loads, making it safe
   to require plugin modules inside.

   ```lua
   -- ✗ bad — telescope.actions required at spec parse time
   opts = { mappings = { i = { ["<C-j>"] = require("telescope.actions").move_down } } }

   -- ✓ good — deferred; runs after Telescope loads
   opts = function()
     local actions = require("telescope.actions")
     return { mappings = { i = { ["<C-j>"] = actions.move_down } } }
   end
   ```

3. **Internal utils (`utils.*`, `config`) may be required at top-level** — they
   are pure Lua files with no plugin dependencies and are always present.

4. **Plugin specs belong in `plugins/`; utility helpers belong in `utils/`.**
   A plugin spec must not contain business logic; a util must not contain plugin
   specs.

### Dependency Injection (DI)

Pass dependencies as function arguments rather than hard-coding module paths
inside functions. This keeps units independently testable and replaceable.

```lua
-- ✗ bad — hard-coded dependency; cannot be tested or swapped
M.do_work = function()
  local tool = require("some.tool")
  tool.run()
end

-- ✓ good — caller injects the tool; function is testable in isolation
---@param tool {run: fun()}
M.do_work = function(tool)
  tool.run()
end
```

For callbacks and autocmd handlers, prefer receiving the dependency via
closure arguments supplied by the plugin framework (e.g. `on_attach(client,
bufnr)`), rather than calling `vim.lsp.get_client_by_id()` internally.

### pcall for Optional Dependencies

Any `require()` that targets a **plugin** (not an internal module) **must**
be wrapped in `pcall`. This ensures the config degrades gracefully when a
plugin is disabled, not installed, or crashes during load.

```lua
-- ✗ bad — crashes Neovim startup if trouble.nvim is not installed
local trouble = require("trouble")
trouble.open({ mode = "lsp_command", params = params })

-- ✓ good — safe even without trouble.nvim
local ok, trouble = pcall(require, "trouble")
if ok then
  trouble.open({ mode = "lsp_command", params = params })
end
```

**Decision table:**

| Module type                            | Top-level require | In-function require | pcall required |
| -------------------------------------- | :---------------: | :-----------------: | :------------: |
| Internal (`utils.*`, `config`, `cmds`) |        ✓          |          ✓          |      ✗         |
| NvChad core (`base46`, `nvchad.*`)     |        ✗          |          ✓          |      ✓         |
| External plugins (`trouble`, `cmp`, …) |        ✗          |          ✓          |      ✓         |

### Module Testability

Design utils to be unit-testable:

- **Pure functions** (no `vim.*` calls) can be tested with plain Lua or
  `nvim --headless -l spec_file.lua`.
- **Neovim-API functions** (`vim.uv.*`, `vim.fn.*`) must use
  `nvim --headless -l spec_file.lua`.
- Tests live under `spec/utils/` and are run with `bash spec/run.sh`.
- Each test file loads `spec/helpers.lua` (minimal `describe`/`it`/`expect`
  framework) via `dofile(vim.env.NVIM_SPEC_DIR .. "/helpers.lua")`.

## Commit Style

- Use lowercase imperative subject lines: `fix:`, `add`, `update`, `scripts:`
- **Never include co-authored-by trailers**
- After every task: automatically commit — do not wait to be asked

