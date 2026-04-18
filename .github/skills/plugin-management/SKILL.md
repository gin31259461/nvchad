# Skill: Plugin Management (lazy.nvim)

## Directory Layout

```
lua/plugins/
├── lsp/           ← LSP config, setup, per-language servers, keymaps
├── debugger/      ← DAP adapters and dap-ui config
├── ui/            ← UI plugins (nvchad, snacks, noice, trouble)
├── db/            ← Database plugins (dadbod)
├── coding.lua     ← Completion, autopairs, surround, comments
├── formatter.lua  ← conform.nvim spec
├── linter.lua     ← nvim-lint spec
├── navigation.lua ← Telescope, file tree, harpoon
├── misc.lua       ← Catch-all for small plugins
└── ...
```

lazy.nvim discovers specs from the `lua/plugins/` directory automatically (via
`import` in `init.lua`).

## Adding a New Plugin

### Step 1 — Choose the right file

| Category         | File                            |
| ---------------- | ------------------------------- |
| LSP-related      | `plugins/lsp/` (sub-directory) |
| Debugging        | `plugins/debugger/`            |
| UI / aesthetics  | `plugins/ui/`                  |
| Editor features  | `plugins/coding.lua`           |
| Navigation       | `plugins/navigation.lua`       |
| Formatting       | `plugins/formatter.lua`        |
| Linting          | `plugins/linter.lua`           |
| Database         | `plugins/db/`                  |
| Anything else    | `plugins/misc.lua`             |

### Step 2 — Write the spec

```lua
return {
  {
    "author/plugin-name",

    -- Lazy-loading (pick at least one):
    event = "BufReadPost",        -- or "VeryLazy", "InsertEnter", etc.
    cmd   = "PluginCmd",          -- load on user command
    ft    = { "python", "lua" },  -- load for specific filetypes
    keys  = {                     -- load on keymap
      { "<leader>pp", "<cmd>PluginCmd<CR>", desc = "Plugin Action" },
    },

    -- Dependencies:
    dependencies = { "nvim-lua/plenary.nvim" },

    -- Configuration:
    opts = {
      -- passed to plugin's setup()
    },

    -- Or use config for manual setup:
    config = function(_, opts)
      require("plugin-name").setup(opts)
      -- additional setup...
    end,
  },
}
```

### Step 3 — Install

Run `:Lazy sync` in Neovim (or restart — lazy.nvim auto-installs on startup).

### Step 4 — Lock

After verifying the plugin works, the `lazy-lock.json` file is auto-updated.
Commit it to pin versions.

## Lazy-Loading Rules

1. **Always lazy-load** — use `event`, `cmd`, `ft`, or `keys`.
2. **Exceptions** (use `lazy = false`):
   - NvChad core UI (`nvchad/ui`, `nvchad/base46`)
   - snacks.nvim (provides global utilities)
   - Colorscheme plugins loaded at startup
3. **`VeryLazy` event** — for plugins needed early but not at startup (e.g.,
   which-key, indent guides).
4. **`BufReadPost` / `BufNewFile`** — for editor-feature plugins that operate
   on buffers.

## Mason Package Registration

Tools installed via Mason are listed in `lua/configs/packages.lua`:

```lua
return {
  treesitter_ensure_installed = { "lua", "python", "c_sharp", ... },

  pkgs_with_lsp_setup = {
    server_name = "mason-package-name",
  },

  pkgs_ensure_installed = {
    "stylua",
    "prettier",
    "csharpier",
    -- formatters, linters, debuggers
  },
}
```

- `pkgs_with_lsp_setup` — LSP servers managed by mason-lspconfig.
- `pkgs_ensure_installed` — all other Mason tools (formatters, linters, DAP
  adapters).

## Formatter / Linter Setup

### Formatters (`plugins/formatter.lua` → conform.nvim)

```lua
formatters_by_ft = {
  lua    = { "stylua" },
  python = { "ruff_format" },
  cs     = { "csharpier" },
}
```

### Linters (`plugins/linter.lua` → nvim-lint)

```lua
linters_by_ft = {
  dockerfile = { "hadolint" },
  markdown   = { "markdownlint" },
}
```

## Conventions

- **Keep specs small** — if a plugin needs > 30 lines of config, extract it
  into its own file or a sub-directory.
- **Don't duplicate keymaps** — if a keymap belongs to a plugin, define it in
  the spec's `keys` field, not in `configs/keymaps.lua`.
- **Use `opts` over `config`** when possible — it's more declarative and
  supports deep-merging by lazy.nvim.
- **Pin versions** — always commit `lazy-lock.json` after adding or updating
  plugins.
- **Test with `:Lazy profile`** — ensure the new plugin doesn't degrade
  startup time below the 100 ms target.
