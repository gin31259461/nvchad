# NvChad Custom Configuration

This is a highly customized Neovim configuration based on ****NvChad v2.5****.
It focuses on providing a comprehensive development environment for Web
(React/Next.js), Python, C# (.NET), and SQL, integrated with modern UI and
debugging capabilities.

<!-- toc -->

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
    * [For windows setup](#for-windows-setup)
    * [How to install](#how-to-install)
- [Uninstall](#uninstall)
- [**Language Support**](#language-support)
- [**Keymappings**](#keymappings)
    * [**General**](#general)
    * [**Navigation & Window**](#navigation--window)
    * [**Search & Jump (Snacks Picker)**](#search--jump-snacks-picker)
    * [**Code Intelligence (LSP)**](#code-intelligence-lsp)
    * [**Debugging (DAP)**](#debugging-dap)
    * [**Database**](#database)
    * [**Harpoon**](#harpoon)
- [**Custom Commands**](#custom-commands)

<!-- tocstop -->

## Features

- ****LSP (Language Server Protocol)****: Complete syntax completion, go-to
  definition, and refactoring capabilities.
- ****DAP (Debug Adapter Protocol)****: Supports breakpoint debugging for Python
  and .NET (C#).
- ****Formatting & Linting****: Uses `conform.nvim` for auto-formatting and
  `nvim-lint` for static code analysis.
- ****Modern UI****:
  - ****Snacks.nvim****: Used for Dashboard, Fuzzy Finder (Picker), Git
    operations, and Notification system.
  - ****Noice.nvim****: Replaces the traditional cmdline, providing enhanced
    messages and popup UIs.
  - ****Neo-tree****: Replaces NvimTree, providing a more powerful file explorer
    with Git status integration.
- ****Database****: Integrated with `vim-dadbod-ui` for querying and managing
  databases directly within Neovim.
- ****Harpoon (v2)****: Fast switching between a small set of frequently used
  files.

## Prerequisites

Before using this configuration, ensure the following tools are installed on
your system:

1. ****Neovim****: Version must be `>= 0.11`.
2. ****Nerd Font****: Terminal must be configured with a font that supports
   icons (e.g., JetBrainsMono Nerd Font).
3. ****System Tools****:
   - `git`, `make`, `gcc` (Windows users need MinGW or Visual Studio Build
     Tools).
   - `ripgrep` (Required for searching).
   - `curl`, `unzip`, `tar`, `gzip`.
4. ****Runtimes****:
   - ****Node.js**** & ****npm/pnpm****: For Web development and installing
     Mason packages.
   - ****Python****: Virtualenv is recommended.
   - ****Dotnet SDK****: For C# development.

## Installation

### For windows setup

- mingw

```ps1
# install
winget install --id=MSYS2.MSYS2  -e

# open msys2 mingw64 shell, install packages
pacman -Sy -y mingw-w64-x86_64-gcc
pacman -Sy -y --needed base-devel mingw-w64-x86_64-toolchain

# add mingw's bin to path, such like C:\msys64\mingw64\bin
```

- cygwin

allow windows use linux tools, such like gzip

```ps1
# install
winget install --id=Cygwin.Cygwin  -e

# add cygwin's bin to path, such like C:\cygwin64\bin
```

### How to install

```bash
# install neovim
# windows -> winget
winget install --id=Neovim.Neovim  -e
winget install -e --id JesseDuffield.lazygit # (optional)

# some plugins need pnpm to build
npm install -g pnpm

# linux
yay -S ttf-firacode-nerd

# after set terminal font as FiraCode Nerd Font
# clone this repo
git clone https://github.com/gin31259461/nvchad.git ~/.config/nvim && nvim
```

- Run `:MasonInstallAll` command after lazy.nvim finishes downloading plugins.
- Reopen neovim

## Uninstall

```bash
# Linux / MacOS (unix)
rm -rf ~/.config/nvim
rm -rf ~/.local/state/nvim
rm -rf ~/.local/share/nvim

# Windows CMD
rd -r ~\AppData\Local\nvim
rd -r ~\AppData\Local\nvim-data

# Windows PowerShell
rm -Force ~\AppData\Local\nvim
rm -Force ~\AppData\Local\nvim-data
```

## **Language Support**

This configuration is optimized for the following languages, with tools
automatically installed via Mason:

| Language        | LSP (Analysis) | Formatter          | Linter       | Debugger   | Notes                         |
| :-------------- | :------------- | :----------------- | :----------- | :--------- | :---------------------------- |
| **Python**      | pyright        | ruff               | ruff         | debugpy    | Supports virtualenv detection |
| **Web (TS/JS)** | vtsls, eslint  | deno_fmt, prettier | eslint_d     | -          | Optimized for Next.js         |
| **C# / .NET**   | roslyn         | csharpier          | -            | netcoredbg | Supports Omnisharp extension  |
| **SQL**         | sqls           | sqlfluff           | sqlfluff     | -          | Supports T-SQL & Jinja        |
| **Lua**         | lua_ls         | stylua             | -            | -          | -                             |
| **Markdown**    | marksman       | markdownlint       | markdownlint | -          | Supports Preview & TOC        |

## **Keymappings**

Below are the most commonly used core keymappings. For a full list, refer to
lua/keymaps.lua or use \<leader\>wk. Leader Key is set to Space.

### **General**

| Key          | Function        | Description                                    |
| :----------- | :-------------- | :--------------------------------------------- |
| \<C-s\>      | Save File       | Save the current file                          |
| \<C-c\>      | Copy Whole File | Copy the entire file content                   |
| \<leader\>fm | Format          | Format current file (LSP/Conform)              |
| \<leader\>/  | Toggle Comment  | Comment/Uncomment lines (Supports visual mode) |
| \<leader\>ch | NvCheatsheet    | View NvChad cheatsheet                         |
| ;            | Command Mode    | Enter command mode ( Mapped to : )             |

### **Navigation & Window**

| Key                 | Function         | Description                               |
| :------------------ | :--------------- | :---------------------------------------- |
| \<C-n\>             | Toggle Neo-tree  | Open/Close File Explorer                  |
| \<leader\>e         | Focus Neo-tree   | Focus on File Explorer                    |
| \<TAB\> / \<S-TAB\> | Next/Prev Buffer | Switch to next/previous buffer            |
| \<leader\>x         | Close Buffer     | Close the current buffer                  |
| \<C-h/j/k/l\>       | Move Window      | Move focus between split windows          |
| \<leader\>h/v       | New Terminal     | Open Horizontal/Vertical Terminal         |
| \<M-h/v/i\>         | Toggle Terminal  | Toggle Float/Horizontal/Vertical Terminal |

### **Search & Jump (Snacks Picker)**

| Key          | Function           | Picker Name  |
| :----------- | :----------------- | :----------- |
| \<leader\>ff | Find Files         | Find Files   |
| \<leader\>fw | Search Text (Grep) | Grep         |
| \<leader\>fb | Find Buffers       | Buffers      |
| \<leader\>fg | Find Git Files     | Git Files    |
| \<leader\>fp | Switch Projects    | Projects     |
| \<leader\>fr | Recent Files       | Recent Files |

### **Code Intelligence (LSP)**

| Key          | Function            | Description                                |
| :----------- | :------------------ | :----------------------------------------- |
| K            | Hover               | Show documentation for symbol under cursor |
| gd           | Goto Definition     | Jump to definition                         |
| gR           | References          | View all references                        |
| \<leader\>ca | Code Action         | Execute code action/fix                    |
| \<leader\>cr | Rename              | Rename symbol                              |
| \<leader\>cR | Rename File         | Rename file (updates imports)              |
| ]] / [[      | Next/Prev Reference | Jump between references in current file    |

### **Debugging (DAP)**

| Key          | Function          | Description                          |
| :----------- | :---------------- | :----------------------------------- |
| \<leader\>db | Toggle Breakpoint | Add/Remove breakpoint                |
| \<leader\>dc | Continue          | Start debugging / Continue execution |
| \<leader\>du | Toggle UI         | Open/Close Debug UI                  |

### **Database**

| Key          | Function    | Description                          |
| :----------- | :---------- | :----------------------------------- |
| \<leader\>dD | Toggle DBUI | Open Database Sidebar                |
| \<leader\>dA | Add Buffer  | Add current SQL file to DBUI context |

### **Harpoon**

| Key         | Function   | Description                      |
| :---------- | :--------- | :------------------------------- |
| \<leader\>a | Add File   | Add file to Harpoon list         |
| \<C-e\>     | Quick Menu | Open Harpoon menu                |
| \<M-S-p/n\> | Prev/Next  | Switch to Prev/Next file in list |

## **Custom Commands**

This configuration includes several custom commands tailored for specific
workflows:

- **.NET**
  - `:DotnetPublish`: Select a .csproj and publish the project (Release mode).
- **Python**
  - `:PyrightReCreateStub`: Delete old stubs and re-generate them (Fixes Pyright
    type hinting issues).
- **System**
  - `:ClearShada`: Clear temporary shada files (Useful for Windows maintenance).
