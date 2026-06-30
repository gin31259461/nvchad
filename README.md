# Neovim Configuration

Personal Neovim configuration built directly on `lazy.nvim`. It keeps the
NvChad UI/theme pieces that are still used through the `Orbit-Lua/nv-ui` and
`Orbit-Lua/nv-base46` forks, then adds an LSP-first workflow, a custom Service
Manager, formatter and linter orchestration, Python and .NET debugging, Git
tools, project navigation, and Copilot-assisted editing.

Use this configuration if you want a ready-to-run Neovim setup for daily
development across Lua, Python, TypeScript, JavaScript, C#, Go, shell,
Markdown, SQL, Docker, TOML, JSON, XML, and Prisma projects.

## Core Value

- Independent `lazy.nvim` editor config with local UI, keymap, option, and
  startup behavior
- Lazy-loaded plugin specs grouped by feature area under `lua/plugins/`
- Managed LSP, formatter, linter, and DAP registry in `lua/config/services.lua`
- Service Manager UI for enabling tools, installing Mason packages, and
  reordering formatter or linter priority by filetype
- Manual formatting by default, so saves do not unexpectedly rewrite buffers
- Python debugging through project virtual environments and .NET debugging
  through `netcoredbg`
- Copilot inline suggestions with optional cmp integration
- Headless Plenary test suite for local utility and Service Manager logic

## Requirements

Required for normal use:

- Neovim 0.12+
- Git
- A Nerd Font, preferably a non-Mono variant
- `ripgrep` for picker search
- `tree-sitter-cli` for nvim-treesitter

Optional tools enable specific features:

- `lazygit` for `<leader>gg`
- Node.js and npm for Node-based tooling and some plugin builds
- `pnpm` for `markdown-preview.nvim`
- `dotnet` for Roslyn, .NET helpers, and .NET debugging
- `debugpy` inside the active Python virtual environment for Python debugging
- `stylua`, `luacheck`, and synced Neovim plugins for repository validation

## Installation

Back up any existing Neovim configuration first.

Linux and macOS:

```bash
git clone https://github.com/gin31259461/nvchad.git ~/.config/nvim
nvim
```

Windows:

```powershell
winget install --id=Neovim.Neovim -e
winget install --id=JesseDuffield.lazygit -e
npm install -g pnpm
git clone https://github.com/gin31259461/nvchad.git $env:LOCALAPPDATA\nvim
nvim
```

For native plugin compilation on Windows, install MSYS2 and MinGW:

```powershell
winget install --id=MSYS2.MSYS2 -e
```

Then install the toolchain from an MSYS2 MinGW64 shell:

```bash
pacman -Sy mingw-w64-x86_64-gcc mingw-w64-x86_64-toolchain
```

Add `C:\msys64\mingw64\bin` to `PATH`.

## First Run

`init.lua` bootstraps `lazy.nvim` automatically. On the first launch, wait for
Lazy to finish installing plugins, then run:

```vim
:MasonInstallAll

:TSInstallAll
```

Restart Neovim after Mason and Treesitter finishes.

`:MasonInstallAll` installs Mason-managed tools derived from
`lua/config/services.lua` and `lua/config/packages.lua`. It does not install
project-local dependencies such as Python `debugpy` or Prisma packages in
`node_modules`.

`:TSInstallAll` installs all default treesitter parsers.

Recommended follow-up setup:

- Run `:Copilot auth` before using Copilot suggestions
- Install `debugpy` in each Python virtual environment that needs debugging
- Install project-local Node dependencies before using Prisma formatting
- Run `:Lazy sync` if plugin state is missing or tests cannot load
  `plenary.nvim`

## Daily Usage

Leader is `<Space>`. Use `<leader>wK` or `<leader>sk` inside Neovim to inspect
the full keymap list.

Common mappings:

- `<C-s>` saves the current file
- `<leader>fm` formats the current file or selection
- `<leader>ff` finds files
- `<leader>fg` finds Git files
- `<leader>sg` greps the project
- `<leader>sw` greps the word or visual selection
- `<leader>fb` lists buffers
- `<leader>gg` opens lazygit
- `<leader>sm` opens the Service Manager
- `<leader>dp` opens the .NET manager
- `<leader>D` opens the dashboard
- `<leader>n` opens notification history
- `<leader>th` switches theme
- `<C-n>` toggles nvim-tree
- `<leader>e` focuses nvim-tree
- `<C-e>` opens the Harpoon menu
- `<leader>ba` adds the current file to Harpoon
- `<M-S-p>` and `<M-S-n>` move through Harpoon items
- `<leader>h` and `<leader>v` open horizontal or vertical terminals
- `<M-h>`, `<M-v>`, and `<M-i>` toggle terminal windows

Common LSP mappings include `gd` for definition, `gR` for references, `gI` for
implementation, `gy` for type definition, `K` for hover, `gK` for signature
help, `<leader>ca` for code actions, `<leader>cr` for rename, and
`<leader>ci` for inlay hints.

DAP mappings use the `<leader>d` prefix. Common commands include `<leader>dt`
for toggle breakpoint, `<leader>dc` for continue, `<leader>dn` for step over,
`<leader>di` for step into, `<leader>do` for step out, `<leader>du` for the
DAP UI, and `<leader>dR` for the REPL.

## Service Manager

Open the Service Manager with `<leader>sm` or `:ServiceManager` after plugins
finish loading.

The Service Manager reads from `lua/config/services.lua` and can:

- Enable or disable registered LSP servers, formatters, linters, and DAP
  adapters
- Install missing Mason-backed tools
- Reorder formatter and linter priority per filetype
- Inspect service details, install state, diagnostics, and runtime errors

Service state is persisted in Neovim's data directory as `service.json`, so a
user's enabled tools and ordering can differ from repository defaults.

Inside the UI:

- `<Space>` toggles a service
- `<CR>`, `o`, or `za` expands details
- `i` installs a tool
- `[` and `]` reorder formatter or linter priority
- `<Tab>` and `<S-Tab>` switch category tabs
- `K` shows a tooltip
- `g?` toggles help
- `q` closes the window

## Project Structure

```text
init.lua                 lazy.nvim bootstrap and top-level startup
lua/chadrc.lua           compatibility shim for nv-ui/nv-base46
lua/config/nvui.lua      Nv UI, base46, Mason, statusline, tabline, and
                         terminal settings
lua/config/              options, keymaps, services, packages, LSP,
                         formatter, linter, filetype, and UI config
lua/plugins/             lazy.nvim plugin specs grouped by feature area
lua/service/             Service Manager state, actions, renderer, and order
lua/cmds/                custom user commands loaded at startup
lua/utils/               shared Lua helpers
lua/test/spec/           Plenary test suite
scripts/tests/           test bootstrap files
```

## Managed Tooling

`lua/config/services.lua` is the canonical registry for managed services.
`lua/config/packages.lua` derives Mason install lists and LSP server names from
that registry.

Registered LSP servers:

```text
pyright, ruff, roslyn, html, cssls, tailwindcss, dockerls,
docker_compose_language_service, clangd, bashls, marksman, prismals,
tombi, jsonls, lua_ls, gopls, powershell_es, lemminx
```

Registered formatters:

```text
stylua, ruff_fix, ruff_organize_imports, ruff_format, shfmt, deno_fmt,
eslint_d, csharpier, markdownlint-cli2, markdown-toc, sql-formatter,
sqlfluff, prisma_fmt, tombi
```

Registered linters:

```text
eslint_d, hadolint, markdownlint-cli2, luacheck, sqlfluff
```

Registered DAP adapters:

```text
python, coreclr
```

## Development

Install the development tools first:

```bash
# examples only; use your system package manager where possible
stylua --version
luacheck --version
nvim --version
```

Validation commands:

```bash
make all   # format lua/, lint lua/, and run headless Plenary tests
make fmt   # format lua/ with stylua
make lint  # lint lua/ with luacheck
make test  # run headless Plenary tests
```

`make test` uses `scripts/tests/minimal.vim` and loads `plenary.nvim` from
Neovim's lazy data directory. If you change `init.lua` or other bootstrap code,
also run:

```bash
nvim --headless "+qall"
```

## Contributing

Keep changes small and tied to one behavior. Before opening a pull request:

1. Explain the user-facing behavior or maintenance problem
2. Update or add tests under `lua/test/spec/` when changing shared utilities,
   Service Manager logic, config derivation, or ordering behavior
3. Run `make all`
4. Run `nvim --headless "+qall"` for startup or bootstrap changes
5. Mention any skipped checks and why they could not run

Bug reports should include:

- Operating system and Neovim version
- What command or keymap triggered the issue
- Relevant `:messages`, `:checkhealth`, or plugin error output
- Whether plugins were synced with `:Lazy sync`
- Whether Mason tools were reconciled with `:MasonInstallAll`

Pull requests should include:

- A short summary of the change
- The affected modules or feature area
- Validation output for `make all`
- Screenshots only when UI layout or highlight behavior changes

## FAQ

### Why does `make test` fail with a missing Plenary module?

The test bootstrap does not install plugins. Run `:Lazy sync` in Neovim and
retry after `plenary.nvim` exists in the lazy data directory.

### Why is `:ServiceManager` unavailable right after startup begins?

The command is registered after Lazy emits `User LazyDone`. Wait for plugin
loading to finish, then run `:ServiceManager` or press `<leader>sm`.

### Why does Python debugging fail?

Python DAP uses `debugpy` from the active virtual environment. Activate the
project environment and install `debugpy` there.

### Why does Prisma formatting fail even after Mason installs tools?

`prisma_fmt` is external to Mason and expects Prisma to be available from the
project's `node_modules`.

### Why does .NET support not load?

Roslyn and .NET helpers are optional and depend on the `dotnet` executable.

### Does this configuration format on save?

No. Formatting is intentionally manual. Use `<leader>fm`.

### Where are Service Manager choices stored?

They are stored in Neovim's data directory as `service.json`, outside this
repository.

## Troubleshooting

- Run `:Lazy sync` if plugin specs or lockfile state drift
- Run `:MasonInstallAll` after changing `lua/config/services.lua`
- Run `:checkhealth` for provider, compiler, and dependency diagnostics
- On Windows, use `:ClearShada` to remove temporary ShaDa files while keeping
  `main.shada`
- If markdown preview fails to build, verify Node.js, npm, and pnpm are
  available

## Uninstall

Linux and macOS:

```bash
rm -rf ~/.config/nvim ~/.local/state/nvim ~/.local/share/nvim
```

Windows:

```powershell
Remove-Item -Recurse -Force ~\AppData\Local\nvim
Remove-Item -Recurse -Force ~\AppData\Local\nvim-data
```
