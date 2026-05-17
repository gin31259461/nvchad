# Neovim Configuration

Personal Neovim config built on [NvChad v2.5](https://github.com/NvChad/NvChad).

## Requirements

| Tool | Purpose |
| --- | --- |
| [Neovim ≥ 0.12](https://github.com/neovim/neovim/releases/tag/stable) | Editor |
| [Nerd Font](https://www.nerdfonts.com/) (non-Mono variant) | Icons & glyphs |
| [Ripgrep](https://github.com/BurntSushi/ripgrep) | Live grep (Snacks) |
| [tree-sitter-cli](https://github.com/tree-sitter/tree-sitter) | Treesitter parser builds |
| [pnpm](https://pnpm.io/) | Build dep for markdown-preview.nvim |
| GCC / MinGW (Windows) | Native plugin compilation |
| [lazygit](https://github.com/jesseduffield/lazygit) _(optional)_ | Git TUI via Snacks |

## Installation

```bash
# Linux / macOS
git clone https://github.com/gin31259461/nvchad.git ~/.config/nvim
nvim
```

After plugins finish installing, run `:MasonInstallAll`, then reopen Neovim.

### Windows

**MinGW** (required for native compilation):

```ps1
winget install --id=MSYS2.MSYS2 -e
# in MSYS2 MinGW64 shell:
pacman -Sy mingw-w64-x86_64-gcc mingw-w64-x86_64-toolchain
# add C:\msys64\mingw64\bin to PATH
```

**Cygwin** (optional — provides Linux tools like `gzip`):

```ps1
winget install --id=Cygwin.Cygwin -e
# add C:\cygwin64\bin to PATH
```

```ps1
winget install --id=Neovim.Neovim -e
winget install --id=JesseDuffield.lazygit -e  # optional
npm install -g pnpm
git clone https://github.com/gin31259461/nvchad.git $env:LOCALAPPDATA\nvim
nvim
```

## Uninstall

```bash
# Linux / macOS
rm -rf ~/.config/nvim ~/.local/state/nvim ~/.local/share/nvim
```

```ps1
# Windows
Remove-Item -Recurse -Force ~\AppData\Local\nvim
Remove-Item -Recurse -Force ~\AppData\Local\nvim-data
```

---

## Features

### UI

| Plugin | Role |
| --- | --- |
| NvChad / base46 | Theme system — default: **tokyonight** (toggle: `<leader>th`) |
| [snacks.nvim](https://github.com/folke/snacks.nvim) | Dashboard, picker, explorer, notifier, indent guides, scroll, lazygit |
| [noice.nvim](https://github.com/folke/noice.nvim) | Styled cmdline, messages, LSP hover & signature popups |
| [nvim-tree](https://github.com/nvim-tree/nvim-tree.lua) | File explorer (`<C-n>` toggle, `<leader>e` focus) |
| [trouble.nvim](https://github.com/folke/trouble.nvim) | Diagnostics, quickfix & location list panel |
| [todo-comments.nvim](https://github.com/folke/todo-comments.nvim) | Highlighted `TODO`/`FIXME`/`WORKAROUND` comments |
| [which-key.nvim](https://github.com/folke/which-key.nvim) | Keymap hints |

### Coding

| Plugin | Role |
| --- | --- |
| [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) | Syntax, highlighting, folding |
| [nvim-treesitter-context](https://github.com/nvim-treesitter/nvim-treesitter-context) | Sticky scope context |
| [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) | Completion engine (LSP, buffer, path, snippets) |
| [LuaSnip](https://github.com/L3MON4D3/LuaSnip) + friendly-snippets | Snippet engine |
| [copilot.lua](https://github.com/zbirenbaum/copilot.lua) | GitHub Copilot inline suggestions (model: `gpt-41-copilot`) |
| [opencode.nvim](https://github.com/nickjvandyke/opencode.nvim) | OpenCode AI integration (ask, execute, session management) |
| [nvim-autopairs](https://github.com/windwp/nvim-autopairs) | Auto-close brackets/quotes |
| [nvim-ts-autotag](https://github.com/windwp/nvim-ts-autotag) | Auto-close/rename HTML tags |
| [vim-matchup](https://github.com/andymass/vim-matchup) | Treesitter-aware `%` matching |
| [lazydev.nvim](https://github.com/folke/lazydev.nvim) | Lua/Neovim API completions |
| [indent-blankline.nvim](https://github.com/lukas-reineke/indent-blankline.nvim) | Indent guides |

### LSP

Managed via [mason.nvim](https://github.com/williamboman/mason.nvim) + [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig).

| Language | Server |
| --- | --- |
| Python | `pyright`, `ruff` |
| TypeScript / JavaScript | `vtsls` + `typescript-tools.nvim` (both active simultaneously) |
| C# / .NET | `roslyn.nvim` _(requires `dotnet` in PATH)_ |
| Lua | `lua_ls` |
| Web | `html`, `cssls`, `tailwindcss` |
| Go | `gopls` |
| C / C++ | `clangd` |
| Bash | `bashls` |
| PowerShell | `powershell_es` |
| Prisma | `prismals` |
| Docker | `dockerls`, `docker_compose_language_service` |
| JSON | `jsonls` |
| Markdown | `marksman` |
| XML | `lemminx` |
| TOML | `tombi` |

### Formatting & Linting

- **Formatter:** [conform.nvim](https://github.com/stevearc/conform.nvim) — stylua, ruff, deno_fmt, eslint_d, csharpier, shfmt, markdownlint-cli2, markdown-toc, sql-formatter, sqlfluff, prisma_fmt, tombi
- **Linter:** [nvim-lint](https://github.com/mfussenegger/nvim-lint) — eslint_d, luacheck, hadolint, markdownlint-cli2, sqlfluff

### Debugging

[Orbit-Lua/nvim-dap](https://github.com/Orbit-Lua/nvim-dap) (fork of mfussenegger/nvim-dap — fixes Windows breakpoints) + [nvim-dap-ui](https://github.com/rcarriga/nvim-dap-ui):

- **Python** — debugpy (venv-detected)
- **.NET** — netcoredbg

### .NET CLI

[dotnet-cli.nvim](https://github.com/Orbit-Lua/dotnet-cli.nvim) + [comet.nvim](https://github.com/Orbit-Lua/comet.nvim) — interactive .NET manager (`<leader>dp`), plus `DotnetBuild`, `DotnetPublish`, and `DotnetGlobalJson` commands.

### Service Manager

Custom interactive UI (`<leader>sm` / `:ServiceManager`) to toggle LSP servers, formatters, linters, and DAP adapters on/off, reorder formatter/linter priority per filetype, and trigger Mason installs — all without editing config files.

| Key | Action |
| --- | --- |
| `<Space>` / `<CR>` | Toggle service on/off |
| `i` | Install via Mason |
| `[` / `]` | Reorder formatter/linter priority |
| `<Tab>` / `<S-Tab>` | Switch category tab |
| `1`–`4` | Jump to category tab directly |
| `K` | Show tooltip |
| `g?` | Toggle help |
| `q` / `<Esc>` | Close |

### Navigation

| Plugin | Role |
| --- | --- |
| [harpoon2](https://github.com/gin31259461/harpoon) | File bookmarks with quick-jump menu (`<C-e>`) |
| [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) | Fuzzy finder (fallback / noice extension) |
| snacks.picker | Primary picker for files, grep, git, LSP |

### Notes _(conditional)_

[obsidian.nvim](https://github.com/obsidian-nvim/obsidian.nvim) — loaded only when `~/OneDrive/Knowledge_Base` exists.

### Git

- [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) — gutter signs, staged/unstaged indicators
- [lazygit](https://github.com/jesseduffield/lazygit) via snacks (`<leader>gg`)

---

## Key Bindings

> Leader key: `<Space>`

### General

| Key | Action |
| --- | --- |
| `<C-s>` | Save file |
| `<C-c>` | Copy whole file |
| `<leader>fm` | Format file (conform) |
| `<leader>fu` | Convert DOS → UNIX line endings |
| `<Esc>` | Clear search highlights |
| `jk` (insert) | Escape to normal mode |
| `;` | Enter command mode |
| `<` / `>` | Dedent / indent line |
| `J` / `K` (visual) | Move selected block down / up |
| `<leader>/` | Toggle comment |
| `<leader>q` | Record macro |
| `+` / `-` | Increment / decrement number (`<C-a>`/`<C-x>` remapped — those are taken by OpenCode) |

### Buffers & Windows

| Key | Action |
| --- | --- |
| `<Tab>` / `<S-Tab>` | Next / prev buffer |
| `<leader>x` | Close current buffer |
| `<leader>bb` | New buffer |
| `<leader>bc` | Close all buffers |
| `<C-h/j/k/l>` | Switch window |
| `<leader>cd` | `cd` to project root |

### Terminal

| Key | Action |
| --- | --- |
| `<leader>h` | New horizontal terminal |
| `<leader>v` | New vertical terminal |
| `<M-h>` | Toggle horizontal terminal |
| `<M-v>` | Toggle vertical terminal |
| `<M-i>` | Toggle floating terminal |
| `<C-x>` (terminal) | Escape terminal mode |

### File Explorer

| Key | Action |
| --- | --- |
| `<C-n>` | Toggle nvim-tree |
| `<leader>e` | Focus nvim-tree |

### Picker (Snacks)

| Key | Action |
| --- | --- |
| `<leader>ff` | Find files |
| `<leader>fr` | Recent files |
| `<leader>fp` | Projects |
| `<leader>fg` | Git files |
| `<leader>fb` | Buffers |
| `<leader>fc` | Config files |
| `<leader>sg` | Grep |
| `<leader>sw` | Grep word / selection |
| `<leader>sb` | Buffer lines |
| `<leader>sB` | Grep open buffers |
| `<leader>sd` | Diagnostics |
| `<leader>sD` | Buffer diagnostics |
| `<leader>sk` | Keymaps |
| `<leader>sR` | Resume last picker |
| `<leader>s"` | Registers |
| `<leader>s/` | Search history |
| `<leader>sa` | Autocmds |
| `<leader>sc` | Command history |
| `<leader>sC` | Commands |
| `<leader>sH` | Highlights |
| `<leader>si` | Icons |
| `<leader>sj` | Jumps |
| `<leader>sl` | Location list |
| `<leader>s'` | Marks |
| `<leader>sM` | Man pages |
| `<leader>sp` | Search plugin specs |
| `<leader>sq` | Quickfix list |
| `<leader>su` | Undo history |

### Git

| Key | Action |
| --- | --- |
| `<leader>gg` | Open lazygit |
| `<leader>gs` | Git status |
| `<leader>gl` | Git log |
| `<leader>gL` | Git log (line) |
| `<leader>gb` | Git branches |
| `<leader>gd` | Git diff hunks |
| `<leader>gS` | Git stash |
| `<leader>gf` | Git log (file) |

### LSP

| Key | Action |
| --- | --- |
| `gd` | Go to definition |
| `gD` | Go to declaration / source definition (TypeScript) |
| `gR` | References / file references (TypeScript) |
| `gI` | Go to implementation |
| `gy` | Go to type definition |
| `K` | Hover documentation |
| `gK` / `<M-k>` | Signature help |
| `<leader>ca` | Code action |
| `<leader>cA` | Source action |
| `<leader>cC` | Run codelens |
| `<leader>cc` | Toggle codelens display |
| `<leader>cr` | Rename symbol |
| `<leader>cR` | Rename file |
| `<leader>ci` | Toggle inlay hints |
| `<leader>cs` | Symbols (Trouble) |
| `<leader>cL` | LSP definitions/refs (Trouble) |
| `<leader>cl` | LSP info |
| `<leader>fd` | Floating diagnostic |
| `]]` / `[[` | Next / prev reference |
| `<a-n>` / `<a-p>` | Next / prev reference (wrap) |

#### TypeScript extras

| Key | Action |
| --- | --- |
| `<leader>co` | Organize imports |
| `<leader>cM` | Add missing imports |
| `<leader>cu` | Remove unused imports |
| `<leader>cD` | Fix all diagnostics |
| `<leader>cV` | Select TypeScript workspace version |

### Debugger (DAP)

| Key | Action |
| --- | --- |
| `<leader>dt` | Toggle breakpoint |
| `<leader>dc` | Continue |
| `<leader>dn` | Step over |
| `<leader>di` | Step into |
| `<leader>do` | Step out |
| `<leader>du` | Toggle DAP UI |
| `<leader>dr` | Restart session |
| `<leader>ds` | New session |
| `<leader>dR` | Toggle REPL |
| `<leader>dl` | Show DAP log |
| `<leader>dw` | Open watch window |

### Harpoon

| Key | Action |
| --- | --- |
| `<leader>a` | Add file to list |
| `<C-e>` | Toggle quick menu |
| `<M-S-p>` / `<M-S-n>` | Prev / next harpoon file |

### Diagnostics (Trouble)

| Key | Action |
| --- | --- |
| `<leader>tx` | Toggle diagnostics |
| `<leader>tX` | Toggle buffer diagnostics |
| `<leader>tL` | Location list |
| `<leader>tQ` | Quickfix list |
| `<leader>tt` | Todo comments (Telescope) |

### .NET Manager

| Key | Action |
| --- | --- |
| `<leader>dp` | Open Dotnet Manager |

### Service Manager

| Key | Action |
| --- | --- |
| `<leader>sm` | Open Service Manager |

### AI

#### Copilot

| Key | Mode | Action |
| --- | --- | --- |
| `<M-l>` | insert | Accept suggestion |
| `<M-]>` | insert | Next suggestion |
| `<M-[>` | insert | Prev suggestion |

#### OpenCode

| Key | Mode | Action |
| --- | --- | --- |
| `<C-a>` | normal/visual | Ask OpenCode |
| `<C-x>` | normal/visual | Execute OpenCode action |
| `<C-.>` | normal/terminal | Toggle OpenCode panel |
| `go` | normal/visual | Add range to session |
| `goo` | normal | Add current line to session |
| `<S-C-u>` / `<S-C-d>` | normal | Scroll OpenCode up / down |

### Other

| Key | Action |
| --- | --- |
| `<leader>mp` | Toggle markdown preview |
| `<leader>th` | Switch NvChad theme |
| `<leader>n` | Notification history |
| `<leader>D` | Open dashboard |
| `<leader>wK` | All which-key mappings |
| `<leader>wk` | Query which-key lookup |
