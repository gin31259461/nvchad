# NvChad Configuration

## Pre-requisites

- [Neovim 0.11](https://github.com/neovim/neovim/releases/tag/stable).
- [Nerd Font](https://www.nerdfonts.com/) as your terminal font.
  - Make sure the nerd font you set doesn't end with <strong>Mono</strong> to
    prevent small icons.
  - <strong>Example : </strong> JetbrainsMono Nerd Font and not
    **<s>JetbrainsMono Nerd Font Mono</s>**
  - The *Mono fonts would work too but icons will slightly look smaller.
- [Tree-sitter-cli](https://github.com/tree-sitter/tree-sitter/blob/master/crates/cli/README.md)
  is requied by nvim-treesitter plugin to install parsers.
- [Ripgrep](https://github.com/BurntSushi/ripgrep) is required for grep
  searching with Telescope <strong>(OPTIONAL)</strong>.
- GCC, Windows users must have [`mingw`](http://mingw-w64.org/downloads)
  installed and set on path.
- Make, Windows users must have
  [`GnuWin32`](https://sourceforge.net/projects/gnuwin32) installed and set on
  path.
- Delete old neovim folders (check commands below)

## Installation

### For Windows Setup

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
