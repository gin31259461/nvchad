# AGENTS Instructions

This repository is a personal Neovim configuration built on
[NvChad v2.5](https://github.com/NvChad/NvChad). `init.lua` is the startup
entrypoint. Most local behavior lives under `lua/`.

Use this file as the operating contract for AI-assisted changes.

## Project Map

- `init.lua` bootstraps `lazy.nvim`, loads NvChad, imports local plugin specs,
  and runs `require("utils").setup()`
- `lua/chadrc.lua` contains NvChad-facing theme, UI, Mason, statusline,
  tabline, and terminal settings
- `lua/config/services.lua` is the canonical registry for managed LSP, DAP,
  formatter, and linter tools
- `lua/config/packages.lua` derives Mason packages and LSP server lists from
  the service registry
- `lua/plugins/` contains lazy.nvim specs grouped by feature area
- `lua/service/` implements the custom Service Manager UI and persistence
- `lua/utils/` contains shared Lua helpers
- `lua/cmds/` contains custom commands loaded during startup
- `lua/test/spec/` contains Plenary tests
- `scripts/tests/minimal.vim` is the headless test bootstrap

## Validation

Run `make all` before finishing changes.

`make all` expands to:

- `make fmt`, which formats `lua/` with `stylua`
- `make lint`, which lints `lua/` with `luacheck`
- `make test`, which runs headless Plenary tests through
  `scripts/tests/minimal.vim`

Requirements:

- `stylua`, `luacheck`, and `nvim` must be available
- Plugins must be synced, including `plenary.nvim` in Neovim's lazy data
  directory

If `make test` cannot load plugins, run `:Lazy sync` in Neovim and retry.

For edits to `init.lua` or other bootstrap/startup paths, also run:

```bash
nvim --headless "+qall"
```

## Development Style

- Follow `.stylua.toml`: 2-space indentation, Unix line endings, 80-column
  target, and automatic quote preference
- Keep Lua modules small and aligned with the existing feature boundaries
- Prefer existing helpers from `lua/utils/` before adding new helper modules
- Keep `lua/config/services.lua` as the single source of truth for managed
  services
- Add or update tests for shared utilities, Service Manager state/order logic,
  service registry derivation, and behavior that can run headlessly
- Use concise comments only when they explain non-obvious behavior

## AI Boundaries

- Do not delete, reset, or rewrite user data outside this repository
- Do not remove Neovim data, state, ShaDa, Mason, lazy.nvim, or
  `service.json` files unless explicitly asked
- Do not run destructive Git commands such as `git reset --hard` or
  `git checkout --` unless explicitly asked
- Do not overwrite unrelated local changes; inspect `git status --short`
  before editing and work around existing changes
- Do not edit `lazy-lock.json` unless the task intentionally changes plugin
  versions or plugin sources
- Do not assume Mason installs project-local dependencies such as Python
  `debugpy` or Prisma packages in `node_modules`
- Do not assume `:ServiceManager` exists before Lazy finishes loading

## Runtime Notes

- `:ServiceManager` is registered after the `User LazyDone` event
- Service Manager state is persisted outside the repo in Neovim's data
  directory as `service.json`
- Enabling a missing Mason-backed service can auto-install its package because
  `missing_package_policy` is `auto`
- Formatting is manual; format-on-save is disabled
- Python debugging requires `debugpy` in the active virtual environment
- .NET support requires the `dotnet` executable
- Prisma formatting expects project-local Node dependencies
- Obsidian integration only loads when `~/OneDrive/Knowledge_Base` exists
- Windows shell behavior and `:ClearShada` are platform-specific
