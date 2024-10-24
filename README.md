# NvChad Config

<!-- toc -->

- [Pre-requisites](#pre-requisites)
- [How to install](#how-to-install)
- [Uninstall](#uninstall)

<!-- tocstop -->

## Pre-requisites

- `Neovim` >= 0.10
- `Nerd Font` as terminal font
  - Make sure the nerd font you set doesn't end with Mono to prevent small icons
  - Example : JetbrainsMono Nerd Font and not ~~JetbrainsMono Nerd Font Mono~~
- `Ripgrep` is required for grep searching with Telescope (OPTIONAL)
- GCC, Windows users must have `mingw` installed and set on path.
- Make, Windows users must have `GnuWin32` installed and set on path.
- Delete old neovim folders (check commands below)

## How to install

Refer to [NvChad](https://nvchad.com/docs/quickstart/install)

```bash
npm install -g pnpm

git clone https://github.com/gin31259461/nvchad.git ~/.config/nvim && nvim
```

- Run `:MasonInstallAll` command after lazy.nvim finishes downloading plugins.
- Run `:Lazy sync` (Notice: may need to run twice)

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
