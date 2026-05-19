# Neovim Config

Modular Neovim config on **NvChad v2.5** + **lazy.nvim**. Entry point:
`init.lua`. Lua source: `lua/`.

---

## Directory Map

```
lua/
├── config/       # options, keymaps, autocmds, packages.lua (canonical tool registry)
│   ├── formatter/   # conform.nvim formatters_by_ft
│   └── linter/      # nvim-lint linters_by_ft
├── plugins/      # lazy.nvim specs — top-level files auto-discovered
│   ├── lsp/         # init, setup, config, keymaps, servers/
│   ├── debugger/    # DAP specs + adapters (python, dotnet)
│   └── ui/          # snacks, noice, trouble, which-key, header, nvchad
├── utils/        # lsp, fs, os, cmp, ui, hl, shell, statusline, str, table, ft
├── cmds/         # custom Ex commands (auto-loaded via fs.scandir)
└── chadrc.lua    # NvChad theme/statusline overrides
```

---

## Conventions

### Plugins (lazy.nvim)

Top-level `lua/plugins/*.lua` files are auto-discovered; subdirs need an
`init.lua`. **Always lazy-load** via `event`, `cmd`, or `ft`. Prefer `opts = {}`
over `config` when no post-setup logic is needed.

### LSP Servers

Registry: `lua/config/packages.lua`. To add a server: (1) add to `packages.lua`,
(2) add config in `lua/plugins/lsp/servers/`, (3) merge via
`lua/plugins/lsp/config.lua`. Base capabilities/`on_init` come from `base.lua` —
do not duplicate.

```lua
---@type Lsp.Server.Module
return {
  servers = { mylangserver = { settings = { ... } } },
  setup   = { mylangserver = function() ... end },  -- optional pre-enable hook
}
```

### Formatters / Linters

Add filetype entries to `lua/config/formatter/init.lua` and
`lua/config/linter/init.lua`. Add Mason tool names to `packages.lua`.

### Keymaps

General: `lua/config/keymaps.lua`. LSP: `lua/plugins/lsp/keymaps.lua` (inside
`on_attach`). Always include `desc`. Leader = `<Space>`. `<C-s>` is reserved for
file save — never remap it.

### Utilities

```lua
local utils = require("utils")
utils.lsp.on_attach(...)  utils.fs.file_exists(path)  utils.os.is_linux()
```

Do not re-implement logic from `lua/utils/`. Use `require("utils").lsp`, not
`require("utils.lsp")` inline.

### Options

Global `vim.opt` calls belong in `lua/config/options.lua`. Only set options
inside plugin configs when they must be set at plugin init time.

### Theme / Highlights

Overrides: `lua/chadrc.lua`. Never override highlight groups in plugin configs.
To clear base46 cache: `:lua require("base46").load_all_highlights()`. Dashboard
headers: `lua/plugins/ui/header.lua` only.

### Environment-Aware Code

Use `require("utils.os")` for OS detection. Conditional plugins check for path
existence before loading (see `notes.lua` pattern).

---

## Code Style

- Formatter: **StyLua** (`.stylua.toml`) — run `stylua lua/` before committing.
- Linter: **luacheck** (`.luacheckrc`).
- No comments unless the _why_ is non-obvious. Never describe _what_ code does.
- Use `vim.keymap.set` (aliased `map`), not `vim.api.nvim_set_keymap`.

---

## Naming Conventions

### Approved abbreviations (only these — spell everything else out)

| Abbr        | Meaning                     | Abbr        | Meaning              |
| ----------- | --------------------------- | ----------- | -------------------- |
| `M`         | Module export               | `ft`        | Filetype             |
| `opts`      | Options                     | `cmd`       | Command              |
| `bufnr`     | Buffer number               | `cfg`       | Local config table   |
| `winid`     | Window ID                   | `fn`/`cb`   | Function/Callback    |
| `ctx`       | Context                     | `ok`/`err`  | pcall returns        |
| `buf`/`win` | Buffer/Window (local scope) | `lsp`       | Language server      |
| `ns`        | Namespace                   | `cwd`       | Current directory    |
| `args`      | Arguments                   | `i`,`j`,`k` | Numeric loop indexes |
| `v`,`k`     | pairs/ipairs iteratees      |             |                      |

Not permitted: `svc`, `diag`, `d`, `sep`, `cat`, `proc`, `act`, `def`, `newf`,
`fname`, `f`, `idx`, `argv`.

### Rules

- **Booleans**: all boolean locals, fields, and predicates must be prefixed
  `is_`, `has_`, `can_`, or `should_`. Normalise `vim.fn` integers at the
  boundary: `vim.fn.filereadable(p) == 1`.
- **Functions**: verb phrases only — `get_server_config`, not `server_config`;
  `render_section`, not `sec`.
- **Module state**: consolidate all mutable upvalues into
  `local _state = { ... }` — no scattered bare privates.
- **Shadowing**: never shadow stdlib names (`os`, `string`, `table`, `math`,
  `io`, …), outer `ok`/`err`, or import aliases.
- **Nested pcall**: use context-prefixed pairs — `server_ok`/`server_err`,
  `parse_ok`/`parse_err`.
- **Unused params**: prefix with `_` — `function(choice, _index)`.

---

## Adding a New Language

1. `packages.lua` — LSP server name(s), Mason tool names, Treesitter parser.
2. `lua/plugins/lsp/servers/` — server config file (or extend `misc.lua`).
3. `lua/config/formatter/init.lua` + `lua/config/linter/init.lua` — filetype
   entries.
4. `lua/plugins/lsp/config.lua` — merge the new server config.
5. `lua/plugins/debugger/` — DAP adapter if needed.

---

## Testing

Tests in `spec/`. Use `spec/helpers` (`describe`/`it`/`expect`). No external
runner — run via headless Neovim.

---

## What NOT to Do

- No double `setup()` calls for the same plugin.
- No `vim.opt` in `lua/plugins/` — use `lua/config/options.lua`.
- No hardcoded tool paths — rely on Mason-managed `$PATH`.
- No plugin without a lazy-load trigger (`event`, `cmd`, `ft`, or
  `lazy = true`).
- No `vim.api.nvim_buf_add_highlight` (deprecated) — use `nvim_buf_set_extmark`
  with `hl_group` + `end_col`.
- No `diagnostics.lua` or `features.lua` standalone files — that logic lives in
  `lua/plugins/lsp/setup.lua`.
- No boolean names/functions without `is_`/`has_`/`can_`/`should_` prefix.
- No noun function names — use verb phrases.
- No unapproved abbreviations.
- No shadowing of stdlib, outer locals, or import aliases.
- No reused `ok`/`err` in nested pcalls — use context-prefixed names.
- No raw `vim.fn` integer returns used as booleans — always `== 1`.

---

## Skills

- Lua programming: `/lua-expert`
