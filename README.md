# NvChad Config

<!-- toc -->

- [Pre-requisites](#pre-requisites)
- [For windows setup](#for-windows-setup)
- [How to install](#how-to-install)
- [Uninstall](#uninstall)

<!-- tocstop -->

## Pre-requisites

- `Neovim` >= 0.11
- `Nerd Font` as terminal font
  - Make sure the nerd font setting doesn't end with Mono to prevent small icons
  - Example : JetbrainsMono Nerd Font and not ~~JetbrainsMono Nerd Font Mono~~
- `Ripgrep` is required for grep searching with Telescope (OPTIONAL)
- Node.js, NPM, Yarn
- GCC, Windows users must have `mingw` installed and set on path.
- Make, Windows users must have `cygwin` installed and set on path.
- Delete old neovim folders (check commands below)

## For windows setup

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

## How to install

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
