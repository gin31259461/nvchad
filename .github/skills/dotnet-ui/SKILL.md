---
name: dotnet-ui
description: A custom two-panel floating UI for command-palette workflows, used by the Dotnet
---

# Skill: Dotnet Commands & UI

## What it is

.NET support is provided by the **`Orbit-Lua/dotnet-cli.nvim`** plugin, with
its interactive UI powered by **`Orbit-Lua/comet.nvim`**. This is an **external
plugin** — do not create a custom `cmds/dotnet.lua` or a custom dotnet-ui
module.

## Plugin Spec

```lua
-- lua/plugins/ui/dotnet.lua
{
  "Orbit-Lua/dotnet-cli.nvim",
  dependencies = { "Orbit-Lua/comet.nvim" },
  cmd = { "DotnetManager", "DotnetBuild", "DotnetPublish", "DotnetGlobalJson" },
  ft = "cs",
  opts = {},
}
```

The plugin is lazy-loaded on `.cs` files or when any of its commands is invoked.

## Available Commands

| Command            | Description                           |
| ------------------ | ------------------------------------- |
| `DotnetManager`    | Opens the interactive .NET manager UI |
| `DotnetBuild`      | Runs `dotnet build`                   |
| `DotnetPublish`    | Runs `dotnet publish`                 |
| `DotnetGlobalJson` | Manages `global.json` SDK pinning     |

## Keymap

```lua
-- lua/config/keymaps.lua
map("n", "<leader>dp", "<cmd>DotnetManager<CR>", { desc = "open dotnet manager" })
```

## Configuring the Plugin

Pass options in the `opts` table in `lua/plugins/ui/dotnet.lua`:

```lua
opts = {
  -- see https://github.com/Orbit-Lua/dotnet-cli.nvim for available options
},
```

## What NOT to Do

- **Do not** create `lua/cmds/dotnet.lua` — all .NET CLI logic lives in the plugin.
- **Do not** create a custom `utils/dotnet-ui.lua` — the UI is provided by
  `comet.nvim`.
- **Do not** add new dotnet commands to `lua/cmds/` — extend via `opts` or
  upstream PRs.

