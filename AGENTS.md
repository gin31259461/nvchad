# AGENTS.md — Neovim Config

Guidelines for AI agents working on this Neovim configuration.

---

## Project Overview

A modular Neovim config built on **NvChad v2.5** using **lazy.nvim** as the plugin manager. Written entirely in Lua. Supports Python, TypeScript/JavaScript, C#/.NET, Lua, Go, Bash, and web languages with full LSP, formatting, linting, and debugging.

**Entry point:** `init.lua`
**Lua source root:** `lua/`

---

## Directory Map

```
lua/
├── config/          # Core settings (options, keymaps, autocmds, filetypes)
│   ├── cmp.lua      # Completion engine options (passed to utils.cmp.setup via lazy main=)
│   ├── packages.lua # Canonical list of LSP servers, formatters, linters, parsers
│   ├── formatter/   # Conform.nvim config
│   └── linter/      # Nvim-lint config
├── plugins/         # Lazy.nvim plugin specs — each file returns LazySpec[]
│   ├── editor.lua       # Treesitter, context, matchup, autotag, ibl, markdown-preview
│   ├── completion.lua   # nvim-cmp, LuaSnip, autopairs, lazydev, cmp sources
│   ├── navigation.lua   # nvim-tree, telescope, harpoon2
│   ├── git.lua          # gitsigns
│   ├── ai.lua           # copilot.lua, opencode.nvim
│   ├── notes.lua        # obsidian.nvim (conditional on ~/OneDrive/Knowledge_Base)
│   ├── formatter.lua    # conform.nvim spec
│   ├── linter.lua       # nvim-lint spec
│   ├── lsp/             # LSP plugin specs + per-server configs
│   │   ├── init.lua         # Mason, nvim-lspconfig, roslyn, typescript-tools plugin specs
│   │   ├── setup.lua        # M module: register_servers, configure_diagnostics,
│   │   │                    #   install_diagnostic_filter, activate_features
│   │   ├── config.lua       # Aggregates server configs from servers/ submodules
│   │   ├── keymaps.lua      # LSP keybindings (lazy-resolved, capability-gated)
│   │   └── servers/         # One file per language group
│   ├── debugger/        # DAP specs + adapter configs
│   │   ├── init.lua     # nvim-dap, nvim-dap-ui plugin specs
│   │   ├── config.lua   # Aggregates DAP adapters
│   │   ├── python.lua   # debugpy adapter
│   │   └── dotnet.lua   # netcoredbg adapter
│   └── ui/              # UI plugin specs
│       ├── init.lua     # Aggregator: requires all ui/* submodules
│       ├── header.lua   # ASCII art dashboard headers (M.dragon, M.wolf, M.claude, …)
│       ├── snacks.lua   # snacks.nvim (dashboard, picker, notifier, lazygit, …)
│       ├── noice.lua    # noice.nvim (cmdline, LSP hover/signature styling)
│       ├── trouble.lua  # trouble.nvim + todo-comments
│       ├── dotnet.lua   # dotnet-cli.nvim (DotnetManager)
│       ├── nvchad.lua   # NvChad UI framework spec
│       └── which-key.lua # which-key.nvim
├── utils/           # Reusable Lua utilities
│   ├── init.lua     # Central aggregator; exposes utils.lsp, utils.fs, utils.os, …
│   ├── cmp.lua      # nvim-cmp setup() + snippet/confirm helpers (used as lazy main=)
│   ├── fs.lua       # Path utilities, root detection, file scanning
│   ├── ft.lua       # Filetype lists (SQL, TypeScript, JavaScript)
│   ├── hl.lua       # Highlight setup: diagnostics, theme-dependent, DAP, undercurl
│   ├── lsp.lua      # LSP lifecycle helpers (on_attach, on_supports_method, …)
│   ├── os.lua       # OS detection, datetime, env vars
│   ├── shell.lua    # Shell configuration (PowerShell / bash)
│   ├── statusline.lua # Custom statusline components (mode, git, LSP, symbols)
│   ├── str.lua      # String utilities
│   ├── table.lua    # Table utilities (unique_by_key)
│   └── ui.lua       # Window sizing, file icons, harpoon display, nvterm safety
├── cmds/            # Custom Ex commands (auto-loaded at startup via fs.scandir)
│   ├── python.lua   # :Pyright* stub commands, venv detection
│   └── system.lua   # :ClearShada (Windows)
└── chadrc.lua       # NvChad overrides (theme, statusline, diagnostics)
```

---

## Key Conventions

### Plugin specs (lazy.nvim)

Every plugin file **at the top level of `lua/plugins/`** is auto-discovered by lazy.nvim and must return a `LazySpec[]`. Subdirectories are treated as modules; lazy imports `plugins.SUBDIR` which resolves to `plugins/SUBDIR/init.lua`. Other files inside subdirectories are **not** auto-discovered — they must be explicitly required from within the `init.lua`.

```lua
return {
  "author/plugin",
  event = "BufReadPost",   -- prefer event/cmd/ft lazy loading
  dependencies = { ... },
  opts = { ... },          -- passed to plugin.setup()
  config = function(_, opts)
    require("plugin").setup(opts)
  end,
}
```

- **Always lazy-load.** Use `event`, `cmd`, or `ft` unless the plugin must load at startup.
- `opts = {}` is preferred over `config` when no post-setup logic is needed.
- Place plugin specs in the most semantically appropriate file under `lua/plugins/`.

### LSP servers

The canonical registry lives in **`lua/config/packages.lua`**. Every server name listed there gets auto-installed by Mason. To add a new language server:

1. Add the server name to the appropriate list in `packages.lua`.
2. Create (or extend) a server config in `lua/plugins/lsp/servers/`.
3. Merge the new server config via `lua/plugins/lsp/config.lua`.

Server config shape:

```lua
-- lua/plugins/lsp/servers/mylang.lua
---@type Lsp.Server.Module
return {
  servers = {
    mylangserver = {
      settings = { ... },
      on_attach = function(client, bufnr) ... end,
    },
  },
  setup = {
    mylangserver = function() ... end, -- optional pre-enable hook
  },
}
```

Capabilities and `on_init` are injected automatically from `lua/plugins/lsp/servers/base.lua` — do not duplicate them.

#### LSP setup pipeline (`lua/plugins/lsp/setup.lua`)

`setup.lua` is a proper M module with four functions called in order from `lsp/init.lua`'s config callback:

| Function | Responsibility |
|---|---|
| `M.register_servers(opts)` | Iterates `packages.lsp_servers`, applies per-server config, calls `vim.lsp.enable` |
| `M.configure_diagnostics(opts)` | Configures signs, virtual text, and float border |
| `M.install_diagnostic_filter()` | Installs a `publishDiagnostics` middleware to drop ignored patterns |
| `M.activate_features(opts)` | Enables inlay hints and code lens via `on_supports_method` (Neovim ≥ 0.10) |

### Formatters / Linters

- **Formatter config:** `lua/config/formatter/init.lua` (conform.nvim). Add a new filetype entry to the `formatters_by_ft` table.
- **Linter config:** `lua/config/linter/init.lua` (nvim-lint). Add to the `linters_by_ft` table.
- **Tool names** (Mason packages) must also be added to `packages.lua` so Mason auto-installs them.

### Keymaps

All general keymaps live in `lua/config/keymaps.lua`. LSP-specific keymaps are in `lua/plugins/lsp/keymaps.lua` and are set inside the `on_attach` callback.

Format:

```lua
map("n", "<leader>xx", "<cmd>SomeCommand<CR>", { desc = "Short description" })
```

- Leader is `<Space>`.
- Always include `desc` — it powers which-key hints.
- Group related keymaps under the same `<leader>` prefix.
- **Do not use `<C-s>` for anything other than file save** — it is globally mapped in `keymaps.lua`.

### Dashboard Headers

ASCII art headers live in **`lua/plugins/ui/header.lua`** as a plain `M` table. The dashboard (`snacks.lua`) imports whichever header it needs:

```lua
preset = { header = require("plugins.ui.header").claude_snack }
```

`*_snack` variants are multi-line strings for snacks.nvim; plain array variants are for NvChad-style dashboards.

### Utilities

Import from the central utils module:

```lua
local utils = require("utils")
utils.lsp.on_attach(...)
utils.fs.file_exists(path)
utils.os.is_linux()
```

Do not re-implement logic that already exists in `lua/utils/`.

### Options

Global vim options are set in `lua/config/options.lua`. Add new options here — do not scatter `vim.opt` calls across plugin configs unless the option is plugin-specific and must be set at plugin init time.

---

## Code Style

- **Formatter:** StyLua. Config: `.stylua.toml`. Run `stylua lua/` before committing.
- **Linter:** luacheck. Config: `.luacheckrc`.
- 2-space indentation, single quotes for strings (StyLua normalises to double).
- No comments unless the reason is non-obvious. Never write what the code does; only write why.
- Prefer `vim.keymap.set` (aliased as `map`) over the legacy `vim.api.nvim_set_keymap`.

---

## Adding a New Language

Checklist for full language support:

1. **`packages.lua`** — add LSP server name(s), Mason tool name(s) for formatter/linter, Treesitter parser name.
2. **`lua/plugins/lsp/servers/`** — add server config (or extend `misc.lua` for simple servers).
3. **`lua/config/formatter/init.lua`** — add formatter entry for the filetype.
4. **`lua/config/linter/init.lua`** — add linter entry for the filetype.
5. **`lua/plugins/lsp/config.lua`** — merge the new server config into the exported table.
6. If debugger support is needed, add a DAP adapter in `lua/plugins/debugger/`.

---

## Testing

Tests live in `spec/`. The test helpers provide a minimal `describe`/`it`/`expect` API:

```lua
local h = require("spec/helpers")
h.describe("my module", function()
  h.it("does X", function()
    h.expect(result).to_equal(expected)
  end)
end)
```

Run specs by sourcing them in Neovim or with a headless Neovim invocation. There is no external test runner — keep specs self-contained.

---

## NvChad / base46 Theme System

- Theme config and overrides: `lua/chadrc.lua`.
- The base46 cache is at `vim.fn.stdpath("data") .. "/nvchad/base46/"`. If theme changes do not appear, clear the cache with `:lua require("base46").load_all_highlights()`.
- Do not override highlight groups directly in plugin configs — use `lua/chadrc.lua` or the NvChad highlight override API.

---

## Conditional / Environment-Aware Code

- Obsidian plugin (`notes.lua`) loads **only** when `~/OneDrive/Knowledge_Base` exists. Follow this pattern for any machine-specific plugin.
- OS detection is available via `require("utils.os")`.
- Copilot model is set in `lua/config/options.lua` (`vim.g.copilot_model`).

---

## What NOT to Do

- Do not call `require("plugin").setup()` more than once for the same plugin.
- Do not add `vim.opt` calls inside `lua/plugins/` files — put them in `lua/config/options.lua`.
- Do not hardcode tool paths; rely on Mason-managed binaries in `$PATH`.
- Do not add a plugin without a `lazy = true` signal (`event`, `cmd`, `ft`, or explicit `lazy = true`).
- Do not duplicate base LSP capabilities — they come from `base.lua` automatically.
- Do not write `require("utils.lsp")` inline when `require("utils").lsp` is already available.
- Do not place dashboard headers in `lua/config/` — they belong in `lua/plugins/ui/header.lua`.
- Do not add `diagnostics.lua` or `features.lua` back as standalone files — that logic lives in `lua/plugins/lsp/setup.lua`.
- Do not add a global `<C-s>` keymap in any plugin config — it is reserved for file save.
