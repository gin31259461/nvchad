# Neovim Configuration

Personal Neovim configuration built on
[NvChad v2.5](https://github.com/NvChad/NvChad), tuned for LSP-first editing,
project navigation, formatter and linter management, Python/.NET debugging,
and Copilot-assisted workflows.

## Requirements

Core tools:

| Tool | Used for |
| --- | --- |
| Neovim 0.11+ | Editor runtime and modern LSP APIs |
| Git | Cloning this config and bootstrapping `lazy.nvim` |
| Nerd Font, non-Mono variant | Icons and UI glyphs |
| ripgrep | Project search in picker UIs |

Optional capability-specific tools:

| Tool | Used for |
| --- | --- |
| lazygit | `<leader>gg` Git UI |
| Node.js and npm | Tree-sitter CLI installs and Node-based plugin builds |
| pnpm | `markdown-preview.nvim` build |
| dotnet | Roslyn, .NET helpers, and .NET debugging |
| debugpy | Python debugging inside the active virtual environment |
| tree-sitter-cli | Parser builds |
| GCC, or MinGW on Windows | Native plugin compilation |

Development commands also require `stylua`, `luacheck`, `nvim`, and synced
plugins, including `plenary.nvim`.

## Installation

Back up any existing Neovim configuration before cloning this repository.

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
plugins to install, then run:

```vim
:MasonInstallAll
```

Restart Neovim after Mason finishes. `:MasonInstallAll` installs the
Mason-managed tools derived from `lua/config/services.lua` and
`lua/config/packages.lua`; it does not install project-local tools.

Manual follow-ups:

- Install `debugpy` in the active Python virtual environment before Python DAP
  sessions
- Install project-local Node dependencies when using Prisma formatting, because
  `prisma_fmt` resolves from `node_modules`
- Run `:Copilot auth` before using Copilot suggestions
- Run `:Lazy sync` if plugin state is missing or test bootstrap cannot load
  `plenary.nvim`

## Daily Usage

Leader is `<Space>`. Use `<leader>wK` or `<leader>sk` inside Neovim to inspect
the full keymap list.

| Key | Action |
| --- | --- |
| `<C-s>` | Save |
| `<leader>fm` | Format current file or selection |
| `<leader>ff` | Find files |
| `<leader>fg` | Find Git files |
| `<leader>sg` | Grep project |
| `<leader>sw` | Grep word or visual selection |
| `<leader>fb` | List buffers |
| `<leader>gg` | Open lazygit |
| `<leader>sm` | Open Service Manager |
| `<leader>dp` | Open .NET manager |
| `<leader>D` | Open dashboard |
| `<leader>n` | Notification history |
| `<leader>th` | Switch theme |
| `<C-n>` | Toggle nvim-tree |
| `<leader>e` | Focus nvim-tree |
| `<C-e>` | Open Harpoon menu |
| `<leader>ba` | Add current file to Harpoon |
| `<M-S-p>` / `<M-S-n>` | Previous or next Harpoon item |
| `<leader>h` / `<leader>v` | Open horizontal or vertical terminal |
| `<M-h>` / `<M-v>` / `<M-i>` | Toggle terminal |

Common LSP mappings include `gd` for definition, `gR` for references, `gI` for
implementation, `gy` for type definition, `K` for hover, `gK` for signature
help, `<leader>ca` for code actions, `<leader>cr` for rename, and `<leader>ci`
for inlay hints.

DAP mappings use the `<leader>d` prefix. Common commands include `<leader>dt`
for toggle breakpoint, `<leader>dc` for continue, `<leader>dn` for step over,
`<leader>di` for step into, `<leader>do` for step out, `<leader>du` for the DAP
UI, and `<leader>dR` for the REPL.

## Service Manager

Open the Service Manager with `<leader>sm` or `:ServiceManager`.

The Service Manager reads from `lua/config/services.lua` and can:

- Enable or disable registered LSP servers, formatters, linters, and DAP
  adapters
- Install Mason-backed tools
- Reorder formatter and linter priority per filetype
- Inspect service details and runtime errors

Inside the UI, `<Space>` toggles a service, `<CR>` expands details, `i` installs
a tool, `[` and `]` reorder priorities, `<Tab>` switches category tabs, `g?`
toggles help, and `q` closes the window.

## Language Tooling

Managed tools are registered in `lua/config/services.lua`. Mason package lists
are derived from that registry in `lua/config/packages.lua`.

LSP servers in the Service Manager registry:

```text
pyright, ruff, roslyn, html, cssls, tailwindcss, dockerls,
docker_compose_language_service, clangd, bashls, marksman, prismals,
tombi, jsonls, lua_ls, gopls, powershell_es, lemminx
```

Formatters:

```text
stylua, ruff_fix, ruff_organize_imports, ruff_format, shfmt, deno_fmt,
eslint_d, csharpier, markdownlint-cli2, markdown-toc, sql-formatter,
sqlfluff, prisma_fmt, tombi
```

Linters:

```text
eslint_d, hadolint, markdownlint-cli2, luacheck, sqlfluff
```

DAP adapters:

```text
python, coreclr
```

Additional plugin-managed language integrations:

- TypeScript and JavaScript use `typescript-tools.nvim`; the Mason
  `typescript-language-server` package is installed so the config can resolve
  `tsserver`
- Roslyn is enabled only when `dotnet` is executable
- Obsidian support loads only when `~/OneDrive/Knowledge_Base` exists

## Project Structure

```text
init.lua                 lazy.nvim bootstrap and top-level startup
lua/chadrc.lua           NvChad theme, UI, Mason, and terminal settings
lua/config/              editor options, keymaps, services, packages, LSP,
                         formatter, linter, and filetype configuration
lua/plugins/             lazy.nvim plugin specs grouped by feature area
lua/service/             Service Manager state, actions, renderer, and ordering
lua/cmds/                custom user commands
lua/utils/               shared Lua helpers
lua/test/spec/           Plenary test suite
scripts/tests/           test bootstrap files
```

## Development

```bash
make all   # format lua/, lint lua/, and run headless Plenary tests
make fmt   # format lua/ with stylua
make lint  # lint lua/ with luacheck
make test  # run headless Plenary tests
```

`make test` uses `scripts/tests/minimal.vim` and loads `plenary.nvim` from
Neovim's lazy data directory. If you change `init.lua` or other bootstrap code,
also run a focused startup check:

```bash
nvim --headless "+qall"
```

## Troubleshooting

- Run `:Lazy sync` if plugin specs or lockfile state drift
- Run `:MasonInstallAll` after changing `lua/config/services.lua`
- Run `:checkhealth` for provider, compiler, and dependency diagnostics
- On Windows, use `:ClearShada` to remove temporary ShaDa files while keeping
  `main.shada`
- If Python debugging fails, activate the project virtual environment and
  install `debugpy`
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
