# AGENTS Instructions

Neovim configuration built on
[NvChad v2.5](https://github.com/NvChad/NvChad). Top-level startup is in
`init.lua`; most local configuration is under `lua/`.

## Validation

Run `make all` before finishing changes.

`make all` expands to:

- `make fmt` formats `lua/` with `stylua`
- `make lint` lints `lua/` with `luacheck`
- `make test` runs headless Plenary tests through `scripts/tests/minimal.vim`

Requirements:

- `stylua`, `luacheck`, and `nvim` must be available
- Plugins must be synced, including `plenary.nvim` in Neovim's lazy data
  directory

If `make test` cannot load plugins, run `:Lazy sync` in Neovim and retry.

For edits to `init.lua` or other bootstrap/startup paths, also run:

```bash
nvim --headless "+qall"
```
