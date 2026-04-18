---
name: dotnet-ui
description: A custom two-panel floating UI for command-palette workflows, used by the Dotnet
---

# Skill: Dotnet-UI — Two-Panel Picker

## What it is

`lua/utils/dotnet-ui.lua` is a custom Telescope-style floating UI with two
panels:

- **Left panel** — prompt input (top, `buftype=prompt`) + scrollable item list
  (below).
- **Right panel** — read-only output with pattern-based line highlighting.

It is used by `lua/cmds/dotnet.lua` (the `DotnetManager` command) but is generic
enough for any command-palette workflow.

## Opening the UI

```lua
require("utils.dotnet-ui").open(commands, { title = "My Manager" })
```

- `commands` — an array of `DotnetUICommand` specs (see below).
- `opts.title` — the floating window title shown in the input panel border.

## Command Spec (`DotnetUICommand`)

```lua
---@class DotnetUICommand
---@field name     string          -- displayed label
---@field icon     string          -- Nerd Font icon string
---@field icon_hl? string          -- highlight group for the icon (default "String")
---@field desc?    string          -- extra text used for fuzzy filtering
---@field action   fun(ctx: DotnetUICtx)
```

### Example

```lua
{
  name    = "Build",
  icon    = "󰒓 ",
  icon_hl = "DiagnosticOk",
  desc    = "dotnet build",
  action  = function(ctx)
    ctx.clear()
    ctx.append("Building…")
    -- call ctx.write / ctx.append / ctx.select as needed
  end,
}
```

## Context API (`DotnetUICtx`)

Every `action` receives a `ctx` table:

| Method                    | Description                                       |
| ------------------------- | ------------------------------------------------- |
| `ctx.write(lines)`        | Append `string` or `string[]` to the output panel |
| `ctx.clear()`             | Clear the entire output panel                     |
| `ctx.append(line)`        | Shorthand for `ctx.write({ line })`               |
| `ctx.select(items, opts)` | Push a sub-selection list onto the left panel     |

### `ctx.select` options

```lua
ctx.select(items, {
  title     = "Select Template",      -- shown in the input-panel border
  on_select = function(item, ctx) end, -- called when user presses Enter
  on_cancel = function() end,          -- called when user presses Esc (optional)
})
```

- `items` can be plain `string[]` **or** an array of tables with
  `{ name, icon, icon_hl?, _raw? }`. The `_raw` field is a convention for
  carrying opaque data through to `on_select`.
- Sub-selections are **filterable** — typing in the input prompt filters the
  items in real time.
- Sub-selections can be **chained**: an `on_select` handler can call
  `ctx.select(...)` again to push another level.
- The parent input text is automatically saved when entering a sub-selection and
  restored when the user cancels out.

## Adding a New Command

1. Open `lua/cmds/dotnet.lua` → `M.commands` table.
2. Append a new spec to the array (order = display order).
3. Write your `action(ctx)` function using the ctx API.
4. If you need project selection, call `select_csproj(ctx, callback)` — it auto-
   selects when there is only one `.csproj`.

### Running a shell command in the output panel

Use the `run_job` helper (local to `cmds/dotnet.lua`):

```lua
run_job(
  { "dotnet", "test", project, "-v", "minimal" },
  ctx,
  function(ctx2) -- optional: called on exit-code 0
    ctx2.append("All tests passed!")
  end
)
```

`run_job` clears the output, prints the command, streams stdout/stderr, and
appends a ✓/✗ status line.

## UI Behaviour Reference

| Key         | Mode  | Context      | Action                                 |
| ----------- | ----- | ------------ | -------------------------------------- |
| `C-j`       | i / n | input / list | Select next item (wraps around)        |
| `C-k`       | i / n | input / list | Select previous item (wraps around)    |
| `j` / `k`   | n     | input / list | Same as C-j / C-k                      |
| `↓` / `↑`   | i     | input        | Same as C-j / C-k                      |
| `Enter`     | i / n | input / list | Execute selected item / confirm sub    |
| `Esc`       | i / n | input        | Cancel sub-selection, or close UI      |
| `q`         | n     | input / list | Same as Esc                            |
| `Tab`       | i / n | input        | Focus output panel                     |
| `Tab`       | n     | output       | Return focus to input                  |
| `Esc` / `q` | n     | output       | Return focus to input (does NOT close) |

## Output Highlighting

Lines written to the output panel are auto-highlighted by pattern:

```lua
{ pat = "^%$ ",            line_hl = "Comment" },         -- command echo
{ pat = "✓",               line_hl = "DiagnosticOk" },
{ pat = "✗",               line_hl = "DiagnosticError" },
{ pat = "Build succeeded", line_hl = "DiagnosticOk" },
{ pat = "Build FAILED",    line_hl = "DiagnosticError" },
{ pat = "[Ww]arning%s",    line_hl = "DiagnosticWarn" },
{ pat = "[Ee]rror%s",      line_hl = "DiagnosticError" },
{ pat = "Restored%s",      line_hl = "DiagnosticOk" },
{ pat = "Passed!",         line_hl = "DiagnosticOk" },
{ pat = "Failed!",         line_hl = "DiagnosticError" },
```

To add new patterns, append to the `OUT_HL_PATTERNS` table at the top of
`lua/utils/dotnet-ui.lua`.

## Internal State (`S`)

All UI state lives in a module-local table `S`. Key fields:

| Field           | Type    | Purpose                                 |
| --------------- | ------- | --------------------------------------- |
| `S.ns`          | int     | Namespace for extmarks; nil = UI closed |
| `S.input_buf`   | int     | Prompt buffer (top-left)                |
| `S.list_buf`    | int     | Item-list buffer (bottom-left)          |
| `S.output_buf`  | int     | Output buffer (right)                   |
| `S.sub`         | table?  | Active sub-selection state              |
| `S.selected`    | int     | 1-based index in main command list      |
| `S.filtered`    | table   | Commands matching current query         |
| `S.last_query`  | string  | Current input text (after prompt)       |
| `S.saved_query` | string? | Saved query when entering sub-selection |

Closing the UI resets `S = {}`.
