# Neovim Configuration

Personal Neovim setup based on [NvChad v2.5](https://github.com/NvChad/NvChad).
It focuses on LSP-driven editing, fast project navigation, formatting, linting,
debugging, and a custom Service Manager for enabling or reordering tools without
editing Lua files.

## Requirements

| Tool | Used for |
| --- | --- |
| [Neovim 0.12+](https://github.com/neovim/neovim/releases/tag/stable) | Editor runtime |
| [Nerd Font](https://www.nerdfonts.com/) non-Mono variant | UI glyph rendering |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | Picker grep |
| [tree-sitter-cli](https://github.com/tree-sitter/tree-sitter) | Parser builds |
| [pnpm](https://pnpm.io/) | `markdown-preview.nvim` build dependency |
| GCC or MinGW on Windows | Native plugin compilation |
| [lazygit](https://github.com/jesseduffield/lazygit) | Optional Git TUI |

## Installation

### Linux and macOS

```bash
git clone https://github.com/gin31259461/nvchad.git ~/.config/nvim
nvim
```

After plugins finish installing, run `:MasonInstallAll`, then restart Neovim.

### Windows

Install Neovim and optional tools:

```powershell
winget install --id=Neovim.Neovim -e
winget install --id=JesseDuffield.lazygit -e
npm install -g pnpm
git clone https://github.com/gin31259461/nvchad.git $env:LOCALAPPDATA\nvim
nvim
```

For native plugin compilation, install MinGW through MSYS2:

```powershell
winget install --id=MSYS2.MSYS2 -e
```

Then, in the MSYS2 MinGW64 shell:

```bash
pacman -Sy mingw-w64-x86_64-gcc mingw-w64-x86_64-toolchain
```

Add `C:\msys64\mingw64\bin` to `PATH`. Cygwin is optional if you want common
Unix tools such as `gzip`.

## What Is Included

- UI: NvChad UI/base46, Snacks dashboard and picker, Noice messages, Trouble
  diagnostics, todo comments, nvim-tree, which-key.
- Editing: Treesitter, `nvim-cmp`, LuaSnip, autopairs, autotag, matchup, Lua
  development helpers, and GitHub Copilot.
- Navigation: Snacks picker for files, grep, Git, LSP, diagnostics, buffers,
  registers, history, and project search; Harpoon for bookmarked files.
- Git: gitsigns plus lazygit integration through Snacks.
- Notes: Obsidian support loads only when `~/OneDrive/Knowledge_Base` exists.
- AI: Copilot suggestions and opencode integration.

## Language Tools

LSP, formatters, linters, and DAP adapters are registered in
`lua/config/services.lua` and installed through Mason where supported.

- LSP: Python, TypeScript/JavaScript, C#/.NET, Lua, HTML, CSS, Tailwind, Go,
  C/C++, Bash, PowerShell, Prisma, Docker, JSON, Markdown, XML, TOML.
- Formatting: `stylua`, `ruff`, `deno_fmt`, `eslint_d`, `csharpier`, `shfmt`,
  `markdownlint-cli2`, `markdown-toc`, `sql-formatter`, `sqlfluff`,
  `prisma_fmt`, `tombi`.
- Linting: `eslint_d`, `luacheck`, `hadolint`, `markdownlint-cli2`, `sqlfluff`.
- Debugging: Python through `debugpy`; .NET through `netcoredbg`.

## Service Manager

Open it with `<leader>sm` or `:ServiceManager`.

Use it to enable or disable LSP servers, formatters, linters, and DAP adapters;
install Mason packages; and reorder formatter or linter priority per filetype.
Inside the UI, `<Space>` toggles an item, `<CR>` expands details, `i` installs
it, `[` and `]` reorder priorities, `<Tab>` switches category tabs, `g?`
toggles help, and `q` closes the window.

## Main Keymaps

Leader is `<Space>`. Use `<leader>wK` or `<leader>sk` to inspect the full keymap
list from inside Neovim.

| Key | Action |
| --- | --- |
| `<C-s>` | Save |
| `<leader>fm` | Format current file |
| `<leader>ff` | Find files |
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
| `<leader>a` | Add file to Harpoon |
| `<leader>h` / `<leader>v` | Open horizontal or vertical terminal |
| `<M-h>` / `<M-v>` / `<M-i>` | Toggle terminal |

Common LSP mappings include `gd` for definition, `gR` for references, `gI` for
implementation, `gy` for type definition, `K` for hover, `gK` for signature
help, `<leader>ca` for code actions, `<leader>cr` for rename, and `<leader>ci`
for inlay hints.

Debugger mappings use the `<leader>d` prefix: `<leader>dt` toggles a breakpoint,
`<leader>dc` continues, `<leader>dn` steps over, `<leader>di` steps into,
`<leader>do` steps out, and `<leader>du` toggles the DAP UI.

## Development

```bash
make fmt    # format Lua
make lint   # run luacheck
make test   # run headless Plenary tests
make ready  # fmt + lint + test
```

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
