# AGENTS Instructions

Neovim configuration built on [NvChad v2.5](https://github.com/NvChad/NvChad).

## Validation

Run `make all` before finishing changes.

`make all` expands to:

- `make fmt` for Lua formatting with `stylua`
- `make lint` for Lua linting with `luacheck`
- `make test` for headless Plenary tests

Notes:

- `make fmt` may rewrite files under `lua/`
- The test harness uses `scripts/tests/minimal.vim` and requires synced plugins,
  including `plenary.nvim`
- For top-level bootstrap edits such as `init.lua`, add a focused startup check
  when practical
