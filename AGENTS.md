# AGENTS

Neovim configuration built on [NvChad v2.5](https://github.com/NvChad/NvChad) +
lazy.nvim. Everything is Lua.

## Repository layout

```
init.lua                  entry point — sets up lazy.nvim, NvChad, options, autocmds, keymaps
lua/
  chadrc.lua              NvChad theme / UI overrides
  config/
    init.lua              shared icon/message/statusline config (re-exported via utils.config)
    autocmds.lua          autocommands
    filetypes.lua         filetype detection overrides
    keymaps.lua           all global keymaps
    lazy.lua              lazy.nvim opts
    options.lua           vim.opt settings
    packages.lua          derives lsp_servers + mason_ensure_installed from services.lua
    services.lua          single source of truth for all managed LSP/DAP/linter/formatter entries
  plugins/                lazy.nvim plugin specs (one file per concern)
    ai.lua, completion.lua, editor.lua, formatter.lua, git.lua
    init.lua (empty — import target), linter.lua, navigation.lua, notes.lua
  service/                Service Manager UI (custom interactive window)
    init.lua              open/close, keymaps
    actions.lua           toggle, install, reorder, tooltip
    config.lua            service_categories, window layout constants
    data.lua              runtime state (active/inactive sets)
    renderer.lua          buffer rendering, live update, help panel
    state.lua             persistent state (vim.g / json)
  cmds/                   user commands loaded at startup (python.lua, system.lua)
  utils/                  utility library — required as `require("utils")`
    init.lua              facade; proxies lazy.core.util; exposes .lsp .ft .shell .os .fs etc.
    cmp.lua fs.lua ft.lua hl.lua logger.lua lsp.lua os.lua
    shell.lua statusline.lua str.lua table.lua ui.lua
  test/
    helpers.lua           minimal describe/it/expect harness (no external deps)
    run.sh
  types/                  LuaCATS annotation stubs (nvim-tree, etc.)
scripts/tests/minimal.vim minimal nvim init for headless plenary test runs
```

## Conventions

### Lua style

- **StyLua** for formatting — run `make fmt` before committing.
- **luacheck** for linting — run `make lint`. Config in `.luacheckrc`; globals
  `vim`, `describe`, `it`, etc. are declared there.
- Use the **module pattern**: `local M = {} … return M`. Colon syntax and
  metatables for OOP when appropriate.
- No side effects at `require` time — initialization goes in `M.setup()` or lazy
  plugin `config`/`opts`.
- Annotate public APIs with LuaCATS (`---@param`, `---@return`, `---@type`,
  `---@class`).

### Services registry

`lua/config/services.lua` is the **single source of truth** for all LSP servers,
DAP adapters, linters, and formatters. `config/packages.lua` derives
`lsp_servers` and `mason_ensure_installed` from it automatically. **Never**
hard-code package names elsewhere — add them to `services.lua` instead.

### Plugin specs

Each plugin file in `lua/plugins/` returns a `LazySpec[]`. Keep specs focused:
one file per concern. Use `event`, `ft`, or `cmd` lazy-loading keys; avoid
`lazy = false` unless necessary.

### Utils facade

Import shared utilities through `require("utils")` (or a sub-module like
`require("utils.fs")`). Do not reach into `lazy.core.util` directly — the facade
already proxies it.

### Service Manager

The `lua/service/` modules communicate through a shared `ui` table (buffer,
window, line_map, category_idx). `renderer` and `actions` are initialized with
references to that table via their `init()` calls. Keep rendering logic in
`renderer.lua` and user-action logic in `actions.lua`.

## Quality gates

```bash
make fmt          # stylua lua/
make lint         # luacheck lua/ --globals vim
make test         # nvim headless plenary suite in lua/test/spec/
make pr-ready     # fmt + lint + test
```

Run `make pr-ready` before opening a PR. Tests live in `lua/test/spec/`; helpers
are in `lua/test/helpers.lua`.

## What to avoid

- Do not add `lazy = false` to plugins that can be event/ft/cmd loaded.
- Do not duplicate Mason package names — derive from `config/services.lua`.
- Do not write comments that restate what the code already says. Only comment
  non-obvious constraints or workarounds.
- Do not add error handling for scenarios that cannot happen in normal
  operation.
- Do not create new utility files — extend existing modules in `lua/utils/`.
