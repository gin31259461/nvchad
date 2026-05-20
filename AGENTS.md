# AGENTS.md

Modular Neovim config on **NvChad v2.5** + **lazy.nvim**. Entry point:
`init.lua`. Lua source: `lua/`.

## Directory Map

```
lua/
├── config/       # options, keymaps, autocmds, packages.lua (canonical tool registry)
│   ├── formatter/   # conform.nvim formatters_by_ft
│   └── linter/      # nvim-lint linters_by_ft
├── plugins/      # lazy.nvim specs — top-level auto-discovered; subdirs need init.lua
│   ├── lsp/         # init, setup, config, keymaps, servers/
│   ├── debugger/    # DAP specs + adapters
│   └── ui/          # snacks, noice, trouble, which-key, header, nvchad
├── utils/        # lsp, fs, os, cmp, ui, hl, shell, statusline, str, table, ft
├── cmds/         # custom Ex commands (auto-loaded via fs.scandir)
└── chadrc.lua    # NvChad theme/statusline overrides
```

## Conventions

**Plugins:** Always lazy-load via `event`, `cmd`, or `ft`. Prefer `opts = {}`
over `config`.

**LSP:** Add server to `packages.lua`, create config in
`lua/plugins/lsp/servers/`, merge in `config.lua`. Base capabilities/`on_init`
from `base.lua` — never duplicate.

```lua
---@type Lsp.Server.Module
return {
  servers = { mylangserver = { settings = { ... } } },
  setup   = { mylangserver = function() ... end },  -- optional pre-enable hook
}
```

**Formatters/Linters:** Entries in `lua/config/formatter/init.lua` +
`lua/config/linter/init.lua`. Mason names in `packages.lua`.

**Keymaps:** General → `lua/config/keymaps.lua`. LSP →
`lua/plugins/lsp/keymaps.lua` (inside `on_attach`). Always include `desc`.
Leader = `<Space>`. `<C-s>` is reserved.

**Utilities:** Use `require("utils").lsp`, not `require("utils.lsp")`. Use
`require("utils").os` for OS detection. Never re-implement utils logic.

**Options:** `vim.opt` in `lua/config/options.lua` only. Plugin configs may set
options only when required at plugin init time.

**Theme:** Highlight overrides in `lua/chadrc.lua` only. Dashboard headers in
`lua/plugins/ui/header.lua` only.

## Code Style

- Formatter: **StyLua** (`.stylua.toml`) — run `stylua lua/` before committing.
- Linter: **luacheck** (`.luacheckrc`).
- No comments unless the _why_ is non-obvious.
- Use `vim.keymap.set` (aliased `map`), not `vim.api.nvim_set_keymap`.

## Naming

| Abbr        | Meaning                | Abbr        | Meaning              |
| ----------- | ---------------------- | ----------- | -------------------- |
| `M`         | Module export          | `ft`        | Filetype             |
| `opts`      | Options                | `cmd`       | Command              |
| `bufnr`     | Buffer number          | `cfg`       | Local config table   |
| `winid`     | Window ID              | `fn`/`cb`   | Function/Callback    |
| `ctx`       | Context                | `ok`/`err`  | pcall returns        |
| `buf`/`win` | Buffer/Window (local)  | `lsp`       | Language server      |
| `ns`        | Namespace              | `cwd`       | Current directory    |
| `args`      | Arguments              | `i`,`j`,`k` | Numeric loop indexes |
| `v`,`k`     | pairs/ipairs iteratees |             |                      |

Not permitted: `svc`, `diag`, `d`, `sep`, `cat`, `proc`, `act`, `def`, `newf`,
`fname`, `f`, `idx`, `argv`.

- **Booleans:** prefix `is_`, `has_`, `can_`, or `should_`. Normalise `vim.fn`
  integers: `vim.fn.filereadable(p) == 1`.
- **Functions:** verb phrases — `get_server_config`, not `server_config`.
- **Module state:** one `local _state = { ... }` — no scattered bare privates.
- **Shadowing:** never shadow stdlib (`os`, `string`, `table`, `math`, `io`…),
  outer `ok`/`err`, or import aliases.
- **Nested pcall:** context-prefixed names — `server_ok`/`server_err`, never
  reuse bare `ok`/`err`.
- **Unused params:** prefix `_` — `function(choice, _index)`.

## Adding a Language

1. `packages.lua` — LSP server, Mason tools, Treesitter parser.
2. `lua/plugins/lsp/servers/` — server config (or extend `misc.lua`).
3. `lua/config/formatter/init.lua` + `lua/config/linter/init.lua`.
4. `lua/plugins/lsp/config.lua` — merge config.
5. `lua/plugins/debugger/` — DAP adapter if needed.

## Testing

`spec/`. Use `spec/helpers` (`describe`/`it`/`expect`). Run via headless Neovim.

## Hard Rules

- No double `setup()` for the same plugin.
- No `vim.opt` in `lua/plugins/`.
- No hardcoded tool paths — rely on Mason-managed `$PATH`.
- No plugin without a lazy-load trigger.
- No `nvim_buf_add_highlight` (deprecated) — use `nvim_buf_set_extmark` with
  `hl_group` + `end_col`.
- No `diagnostics.lua` or `features.lua` standalone files — logic lives in
  `lua/plugins/lsp/setup.lua`.
