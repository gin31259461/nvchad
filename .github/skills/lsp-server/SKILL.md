---
name: lsp-server
description: "Configure LSP servers with a modular, capability-aware approach."
---

# Skill: LSP Server Configuration

## Architecture

```
lua/plugins/lsp/
├── servers/
│   ├── base.lua        ← shared diagnostics, capabilities, on_init
│   ├── lua_ls.lua      ← Lua language server
│   ├── python.lua      ← pyright + ruff
│   ├── typescript.lua  ← vtsls
│   ├── dotnet.lua      ← roslyn (.NET)
│   └── misc.lua        ← catch-all for simpler servers
├── config.lua          ← merges base + all server modules → Lsp.Config.Spec
├── setup.lua           ← iterates config, calls lspconfig/setup
├── keymaps.lua         ← capability-aware LSP keymaps
├── diagnostics.lua     ← configure signs/virtual-text + filter middleware
└── features.lua        ← inlay hints + code lens activation (nvim ≥ 0.10)
```

### Data flow

1. `base.lua` returns `---@type Lsp.Config.Spec` with diagnostics, capabilities,
   and `on_init`.
2. `config.lua` requires base, then deep-merges each module in `server_modules`.
3. `setup.lua` iterates the merged spec and calls `lspconfig[name].setup(cfg)`
   (or defers to `spec.setup[name]()` for custom setups like roslyn.nvim).
4. `keymaps.lua` is called from `on_attach` and only registers keymaps for
   capabilities the server actually supports.
5. `diagnostics.lua:configure(opts)` applies sign definitions, virtual-text icon
   resolution, and commits `vim.diagnostic.config()`.
6. `diagnostics.lua:install_filter_middleware()` installs a handler on
   `textDocument/publishDiagnostics` that drops diagnostics matching patterns in
   `config.ignore_msgs.lsp`.
7. `features.lua:activate(opts)` enables inlay hints and code lens via
   capability-aware `on_supports_method` hooks (no-ops on Neovim < 0.10).

## Adding a New LSP Server

### Step 1 — Register the package

In `lua/config/packages.lua`, add the server to `pkgs_with_lsp_setup`:

```lua
pkgs_with_lsp_setup = {
  -- key = lspconfig name, value = Mason package name
  your_server = "mason-package-name",
},
```

Also add any companion tools (formatter, linter) to the local `pkgs_only` list in the same file.

### Step 2 — Create or extend a server module

Create `lua/plugins/lsp/servers/<lang>.lua` (or add to `misc.lua` for simple
servers):

```lua
---@type Lsp.Server.Module
return {
  servers = {
    your_server = {
      settings = {
        -- server-specific settings
      },

      -- Optional: per-server keymaps (LazyKeysSpec format)
      keys = {
        { "gd", function() ... end, desc = "Goto Definition (Lang)" },
      },

      -- Optional: per-server on_attach
      on_attach = function(client, bufnr) ... end,
    },
  },

  -- Optional: custom setup function (bypasses lspconfig)
  setup = {
    your_server = function()
      -- e.g., use a dedicated plugin like roslyn.nvim
    end,
  },
}
```

### Step 3 — Register the module

In `lua/plugins/lsp/config.lua`, add the module path to `server_modules`:

```lua
local server_modules = {
  "plugins.lsp.servers.lua_ls",
  "plugins.lsp.servers.typescript",
  "plugins.lsp.servers.python",
  "plugins.lsp.servers.dotnet",
  "plugins.lsp.servers.misc",
  "plugins.lsp.servers.your_lang",  -- ← add here
}
```

### Step 4 — Verify

1. Open Neovim, run `:LspInfo` in a file of the target language.
2. Check `:Mason` — the package should be installed.
3. Run `:checkhealth lsp` for diagnostics.

## Type Reference

### `Lsp.Config.Spec` (base config)

```lua
---@class Lsp.Config.Spec
---@field servers         Lsp.Config.Servers
---@field on_init         fun(client, init_result)
---@field capabilities    lsp.ClientCapabilities
---@field disable_default_settings {[string]: table}
---@field setup           {[string]: fun()}
---@field diagnostics     vim.diagnostic.Opts
---@field inlay_hints     {enabled: boolean, exclude: table}
---@field codelens        {enabled: boolean, autocmd: boolean}
```

### `Lsp.Server.Module` (per-language file)

```lua
---@class Lsp.Server.Module
---@field servers? Lsp.Config.Servers
---@field setup?   {[string]: fun()}
```

## Conventions

- **Semantic tokens are disabled globally** in `base.lua` via `on_init`.
  Override per-server only with good reason.
- **`disable_default_settings`** — if a server needs its own `on_init` that
  conflicts with the base one, list the conflicting fields:
  ```lua
  disable_default_settings = { roslyn = { "on_init" } }
  ```
- **Capability-aware keymaps** — `keymaps.lua` checks
  `client:supports_method(...)` before registering. This avoids dead keymaps for
  servers that don't support certain LSP methods.
- **Diagnostic filtering** — `diagnostics.lua:install_filter_middleware()`
  installs a `textDocument/publishDiagnostics` handler override that silently
  drops messages matching patterns in `config.ignore_msgs.lsp`. This is named
  explicitly as middleware to communicate the GoF Middleware pattern.
