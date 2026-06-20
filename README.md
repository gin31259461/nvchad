# Neovim Configuration

Neovim configuration built on [NvChad v2.5](https://github.com/NvChad/NvChad).
It is tuned for LSP-first editing, fast project navigation, formatter and linter
management, Python/.NET debugging, and AI-assisted workflows.

## Highlights

- NvChad UI with Base46 themes, Snacks dashboard/picker/notifier, Noice,
  Trouble, nvim-tree, which-key, and custom borders
- LSP setup for Python, TypeScript/JavaScript, C#/.NET, Lua, HTML, CSS,
  Tailwind, Go, C/C++, Bash, PowerShell, Prisma, Docker, JSON, Markdown, XML,
  and TOML
- Formatter and linter orchestration through Conform, nvim-lint, Mason, and a
  custom Service Manager
- Debug adapters for Python through `debugpy` and C#/.NET through `netcoredbg`
- Treesitter, completion, snippets, autopairs, autotag, matchup, markdown
  preview, Git signs, lazygit, Harpoon, Copilot
- Obsidian support that loads only when `~/OneDrive/Knowledge_Base` exists

## Requirements

| Tool | Used for |
| --- | --- |
| [Neovim 0.11+](https://github.com/neovim/neovim/releases/tag/stable) | Editor runtime with `vim.lsp.config` and `vim.lsp.enable` |
| [Git](https://git-scm.com/) | Cloning this config and bootstrapping lazy.nvim |
| [Nerd Font](https://www.nerdfonts.com/) non-Mono variant | Icons and UI glyphs |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | Project grep in pickers |
| [tree-sitter-cli](https://github.com/tree-sitter/tree-sitter) | Treesitter parser builds |
| [pnpm](https://pnpm.io/) | `markdown-preview.nvim` build dependency |
| GCC, or MinGW on Windows | Native plugin compilation |

Optional tools:

- `lazygit` for `<leader>gg`
- `dotnet` for Roslyn, .NET project helpers, and .NET debugging
- `debugpy` installed in the active Python virtual environment for Python DAP

## Installation

Back up any existing Neovim configuration before cloning this repository.

### Linux and macOS

```bash
git clone https://github.com/gin31259461/nvchad.git ~/.config/nvim
nvim
```

### Windows

```powershell
winget install --id=Neovim.Neovim -e
winget install --id=JesseDuffield.lazygit -e
npm install -g pnpm
git clone https://github.com/gin31259461/nvchad.git $env:LOCALAPPDATA\nvim
nvim
```

For native plugin compilation, install MSYS2 and MinGW:

```powershell
winget install --id=MSYS2.MSYS2 -e
```

Then install the toolchain from an MSYS2 MinGW64 shell:

```bash
pacman -Sy mingw-w64-x86_64-gcc mingw-w64-x86_64-toolchain
```

Add `C:\msys64\mingw64\bin` to `PATH`.

## First Run

`init.lua` bootstraps `lazy.nvim` automatically. When Neovim opens for the first
time, wait for plugins to install, then run:

```vim
:MasonInstallAll
```

Restart Neovim after Mason finishes installing language servers, formatters,
linters, and debug adapters.

## Service Manager

Open the Service Manager with `<leader>sm` or `:ServiceManager`.

The Service Manager reads from `lua/config/services.lua` and lets you:

- Enable or disable LSP servers, formatters, linters, and DAP adapters
- Install Mason-backed tools
- Reorder formatter and linter priority per filetype
- Inspect service details and runtime errors

Inside the UI, `<Space>` toggles a service, `<CR>` expands details, `i` installs
a tool, `[` and `]` reorder priorities, `<Tab>` switches category tabs, `g?`
toggles help, and `q` closes the window.

## Language Tools

Managed tools are registered in `lua/config/services.lua`. Mason package lists
are derived from that registry in `lua/config/packages.lua`.

LSP:

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

DAP:

```text
python, coreclr
```

Python debugging expects an active virtual environment with `debugpy` installed.
.NET debugging uses `netcoredbg`; on Windows the adapter is resolved from the
Mason package directory.

## Keymaps

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
make fmt    # format Lua with stylua
make lint   # lint Lua with luacheck
make test   # run headless Plenary tests
make ready  # fmt + lint + test
```

## Troubleshooting

- Run `:Lazy sync` if plugin specs or lockfile state drift
- Run `:MasonInstallAll` after changing `lua/config/services.lua`
- Run `:checkhealth` for provider, compiler, and dependency diagnostics
- On Windows, use `:ClearShada` to remove temporary ShaDa files while keeping
  `main.shada`
- If Python debugging fails, activate the project virtual environment and
  install `debugpy`

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
