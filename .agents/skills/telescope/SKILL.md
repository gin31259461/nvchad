---
name: telescope
description: Apply telescope.nvim API knowledge when configuring pickers, building custom finders, wiring extensions, or writing keymaps that invoke fuzzy-finder UIs. Use whenever code touches `require("telescope...")` — setup defaults, builtin pickers, themes, actions, custom `pickers.new`, finders/sorters/previewers, entry_maker shape, or extension loading. Picks the right namespace, follows the prompt-buffer mapping conventions, and avoids the common config traps (sorter-as-function, global `file_ignore_patterns`, `attach_mappings` return value).
---

# Telescope

API-level guidance for working with telescope.nvim — the fuzzy finder used throughout this config. This skill is about *how to use telescope correctly*: which module owns what, how setup merging works, how to build a custom picker that respects user config, and how `attach_mappings` interacts with the default action map. Pair it with the `neovim` skill for editor-side concerns and the `lua` skill for module structure.

The plugin source lives at `~/.local/share/nvim/lazy/telescope.nvim/`. When unsure, read it — `lua/telescope/config.lua` is the authoritative defaults list and `developers.md` is the canonical custom-picker tutorial.

## When to Use

- Calling any `require("telescope...")` module in a plugin spec, keymap, or user command.
- Configuring `telescope.setup({ defaults, pickers, extensions })`.
- Loading or authoring an extension (`load_extension`, `register_extension`).
- Building a custom picker with `pickers.new`, `finders.new_*`, `sorters`, `previewers`.
- Replacing or extending default mappings via `attach_mappings`.
- Wiring telescope into another flow (`vim.ui.select` via `ui-select`, LSP picker overrides).
- Diagnosing "my picker doesn't pick up user config" / "sorter ignored" / "preview missing" issues.

## When Not to Use

- Pure editor-side code with no telescope module reference — use `neovim`.
- Lua module/architecture decisions unrelated to pickers — use `lua`.
- lazy.nvim spec mechanics (event/ft/cmd/keys/opts) — those are general lazy conventions.
- One-off keymap edits that just call a builtin (`builtin.find_files`) — no design decision involved.

## Decision Map: Which Module

| You want to... | Use |
|----------------|-----|
| Configure telescope globally | `require("telescope").setup({...})` |
| Load an extension | `require("telescope").load_extension("fzf")` |
| Access loaded extension | `require("telescope").extensions.<name>.<picker>` |
| Call a builtin picker | `require("telescope.builtin").<name>(opts)` |
| Wrap a picker in a theme | `require("telescope.themes").get_{dropdown,cursor,ivy}(opts)` |
| Build a custom picker | `require("telescope.pickers").new(opts, picker_opts)` |
| Static list of entries | `require("telescope.finders").new_table { results, entry_maker }` |
| Run a one-shot command for entries | `finders.new_oneshot_job { command, entry_maker }` |
| Live-updating job (re-runs per keystroke) | `finders.new_job { fn_command, entry_maker }` |
| Resolve user-configured sorter | `require("telescope.config").values.generic_sorter(opts)` or `.file_sorter(opts)` |
| Resolve user-configured previewer | `conf.file_previewer(opts)` / `conf.grep_previewer(opts)` |
| Define a custom action | `require("telescope.actions")` + `:replace()` / `:enhance()` |
| Inspect picker state inside an action | `require("telescope.actions.state")` |
| Format multi-column entries | `require("telescope.pickers.entry_display").create({...})` |
| Add an entry helper for a known shape | `require("telescope.make_entry").set_default_entry_mt(entry, opts)` |

Always pull defaults through `require("telescope.config").values.*` (typically aliased `local conf = require("telescope.config").values`). It returns the **merged** user+plugin config — using the raw module bypasses user overrides.

## Setup Pattern

```lua
require("telescope").setup({
  defaults = {
    -- merged into every picker
    sorting_strategy = "ascending",
    layout_strategy = "horizontal",
    layout_config = { width = 0.85, height = 0.85, preview_cutoff = 120 },
    prompt_prefix = " ",
    selection_caret = " ",
    path_display = { "truncate" },
    vimgrep_arguments = {
      "rg", "--color=never", "--no-heading",
      "--with-filename", "--line-number", "--column", "--smart-case",
    },
    mappings = {
      i = { ["<C-j>"] = "move_selection_next", ["<C-k>"] = "move_selection_previous" },
      n = { ["q"] = "close" },
    },
  },
  pickers = {
    find_files = { hidden = true, follow = true },
    live_grep   = { additional_args = function() return { "--hidden" } end },
  },
  extensions = {
    fzf = { fuzzy = true, override_generic_sorter = true, override_file_sorter = true },
    ["ui-select"] = { require("telescope.themes").get_dropdown({}) },
  },
})

require("telescope").load_extension("fzf")
require("telescope").load_extension("ui-select")
```

Rules:
- `defaults` applies to every picker. `pickers.<name>` overrides per-builtin. `extensions.<name>` is opaque to telescope and forwarded to the extension's `setup`.
- `load_extension` must come **after** `setup` and is the only way to activate sorter/previewer overrides from `fzf-native` and friends.
- `vimgrep_arguments` must include `--no-heading --with-filename --line-number --column` for ripgrep output parsing. Color codes break the parser — keep `--color=never`.
- `mappings` accept either action names (strings) or `actions.*` functions. Use strings for built-in actions; functions for custom ones.

## Builtin Pickers (canonical set)

`local builtin = require("telescope.builtin")` then:

| Category | Pickers |
|----------|---------|
| Files | `find_files`, `git_files`, `live_grep`, `grep_string`, `current_buffer_fuzzy_find`, `oldfiles` |
| Git | `git_commits`, `git_bcommits`, `git_branches`, `git_status`, `git_stash` |
| LSP | `lsp_references`, `lsp_definitions`, `lsp_type_definitions`, `lsp_implementations`, `lsp_document_symbols`, `lsp_dynamic_workspace_symbols`, `lsp_incoming_calls`, `lsp_outgoing_calls` |
| Vim | `buffers`, `marks`, `registers`, `keymaps`, `jumplist`, `quickfix`, `loclist`, `help_tags`, `man_pages`, `commands`, `command_history`, `search_history`, `vim_options` |
| Misc | `treesitter` (AST symbols), `resume` (re-open last picker), `pickers` (cached pickers), `builtin` (meta) |

All accept the same opts shape `(picker_overrides, theme_opts_merged)`. Pass a theme wrapper for ad-hoc UI tweaks:

```lua
builtin.find_files(require("telescope.themes").get_dropdown({ previewer = false }))
```

## Themes

```lua
local themes = require("telescope.themes")
themes.get_dropdown({ previewer = false })  -- centered, no preview by default
themes.get_cursor({})                       -- follows cursor (small, for ui-select)
themes.get_ivy({})                          -- bottom_pane, file-manager feel
```

Each is a function `(opts) -> opts` — it merges theme defaults into your opts and returns the result. Pass the result directly to a picker.

## Custom Picker Pattern

```lua
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local function colors_picker(opts)
  opts = opts or {}
  pickers.new(opts, {
    prompt_title = "Colors",
    finder = finders.new_table({
      results = { "red", "green", "blue" },
      entry_maker = function(item)
        return { value = item, display = item, ordinal = item }
      end,
    }),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, _map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local entry = action_state.get_selected_entry()
        vim.notify("picked: " .. entry.value)
      end)
      return true
    end,
  }):find()
end
```

Rules:
- `pickers.new(opts, spec):find()` — `opts` is the user-passed (and theme-merged) table; `spec` describes the picker.
- Pull sorter and previewer from `conf.*` so user overrides (e.g. `fzf-native`) apply. Hard-coding `sorters.get_fzy_sorter()` defeats their setup.
- `attach_mappings` **must** return `true` (keep defaults) or `false` (drop defaults). The bare `function ... end` shape with no `return` returns `nil` and is treated as `false` — usually a bug.
- Use `actions.select_default:replace(fn)` to swap `<CR>` behavior without losing other default keys. `:enhance({ post = fn })` runs *after* the default.

### Finder variants

| Finder | Use when |
|--------|----------|
| `finders.new_table { results, entry_maker }` | Static list known up front |
| `finders.new_oneshot_job(cmd, { entry_maker })` | One process run, parse stdout (think `ls`, `fd`) |
| `finders.new_job(fn_cmd, entry_maker, max)` | Re-run per prompt change (think `live_grep`) |

`entry_maker` is optional for table finders if entries are already in shape. For job finders it's how you turn each stdout line into an entry table.

### Entry shape

```lua
{
  value   = original_payload,  -- any type; what actions read
  display = "shown in list",   -- string OR function(entry) -> string, hl
  ordinal = "sortable string", -- what the sorter scores against

  -- optional, for file-aware features (preview, quickfix send):
  filename = "/abs/path",
  lnum = 42,
  col  = 5,
  bufnr = 7,

  -- optional:
  valid = false,               -- hide entry from results
}
```

`display`, `ordinal`, and `value` are the only required keys. The fastest way to keep behavior consistent with builtins is to layer the entry metatable:

```lua
local make_entry = require("telescope.make_entry")
entry_maker = function(item)
  return make_entry.set_default_entry_mt({
    value = item,
    display = item.label,
    ordinal = item.label,
  }, opts)
end
```

### Multi-column display

```lua
local entry_display = require("telescope.pickers.entry_display")
local displayer = entry_display.create({
  separator = " ",
  items = { { width = 20 }, { width = 40 }, { remaining = true } },
})

entry_maker = function(item)
  return {
    value = item,
    ordinal = item.name .. " " .. item.path,
    display = function(e)
      return displayer({
        { e.value.name, "Identifier" },
        { e.value.path, "Comment" },
        e.value.note,
      })
    end,
  }
end
```

`display` as a function defers rendering until the row is visible — cheaper for large result sets.

## Actions & action_state

```lua
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
```

Common actions (callable as `actions.<name>(prompt_bufnr)` or used as mapping values):

| Group | Members |
|-------|---------|
| Selection | `select_default`, `select_horizontal`, `select_vertical`, `select_tab` |
| Movement | `move_selection_next`, `move_selection_previous`, `move_to_top`, `move_to_middle`, `move_to_bottom` |
| Multi-select | `toggle_selection`, `add_selection`, `remove_selection`, `select_all`, `drop_all`, `toggle_all` |
| Preview | `preview_scrolling_up`, `preview_scrolling_down` |
| Window | `close`, `layout.toggle_preview`, `layout.cycle_layout_next` |
| Quickfix | `send_to_qflist`, `send_selected_to_qflist`, `open_qflist` |

Each action object supports:

```lua
actions.select_default:replace(fn)            -- swap implementation
actions.select_default:enhance({ post = fn }) -- run fn after the default
actions.select_default:replace_if(cond, fn)   -- conditional swap
```

State inspection inside an action:

```lua
local picker = action_state.get_current_picker(prompt_bufnr) -- the picker object
local entry  = action_state.get_selected_entry()             -- single selection
local prompt = action_state.get_current_line()               -- prompt text
local multi  = picker:get_multi_selection()                  -- {} if none
```

For multi-select handlers, iterate `multi` and **fall back** to `entry` when it's empty — the user may have hit `<CR>` without toggling.

## Extensions

Loading:

```lua
require("telescope").setup({ ... })
require("telescope").load_extension("fzf")
local results = require("telescope").extensions.fzf.<picker>(opts)
```

Authoring:

```lua
-- lua/telescope/_extensions/my_ext.lua  (must live under this path)
return require("telescope").register_extension({
  setup = function(ext_config, telescope_config)
    -- one-time init; ext_config is whatever the user passed in extensions.my_ext
  end,
  exports = {
    my_picker = function(opts) ... end,
  },
})
```

Common extensions used in this repo / ecosystem:
- **telescope-fzf-native.nvim** — C sorter; orders of magnitude faster than the default fzy sorter. Requires `override_generic_sorter` / `override_file_sorter` in its extension config to take effect.
- **telescope-ui-select.nvim** — routes `vim.ui.select` through telescope. Configure with a theme: `extensions["ui-select"] = { themes.get_dropdown({}) }`.
- **telescope-file-browser.nvim** — file manager picker.

## Workflow

### Step 1: Decide builtin vs. custom

If a builtin already covers the use case, use it with opts/theme. Don't reimplement `find_files`.

### Step 2: For custom pickers, pull from `conf`

```lua
local conf = require("telescope.config").values
sorter    = conf.generic_sorter(opts),
previewer = conf.file_previewer(opts),
```

Hard-coded sorters/previewers ignore the user's setup and any active extensions.

### Step 3: Wire `attach_mappings` correctly

- `:replace` for swapping a key's behavior.
- `:enhance({ post = fn })` to chain after the default.
- `map(mode, lhs, fn_or_action_name)` for new keys.
- **Always** `return true` (keep defaults) or `false` (drop them).

### Step 4: Shape entries deliberately

`value` holds the payload, `ordinal` is what gets fuzzy-matched, `display` is what shows. They are usually *different* strings — don't conflate.

### Step 5: Validate

In a running Neovim:
1. Open the picker, confirm results appear.
2. Type a query, confirm sorting works.
3. Press `<CR>` — confirm the action fires.
4. Press `<C-v>`, `<C-x>`, `<C-t>` — confirm default mappings still work (proves you returned `true`).
5. `:Telescope keymaps` — confirm your custom mappings have descriptions.

## Validation

- [ ] Sorter and previewer come from `conf.*(opts)`, not raw `sorters.*` / `previewers.*`.
- [ ] `attach_mappings` returns `true` or `false` explicitly.
- [ ] Custom actions use `actions.<x>:replace(fn)` rather than overwriting the table directly.
- [ ] Multi-select handlers check `picker:get_multi_selection()` and fall back to the current entry.
- [ ] Extensions are `load_extension`-ed **after** `setup`.
- [ ] `vimgrep_arguments` keeps `--no-heading --with-filename --line-number --column` and `--color=never`.
- [ ] `file_ignore_patterns` is set per-picker when scope-specific, not globally if it would hide LSP results.
- [ ] Custom finders' entry tables have `value`, `display`, `ordinal` (and `filename`/`lnum` for file-aware flows).
- [ ] `display` as a function is used for expensive rendering, not for every entry.
- [ ] Themes are applied by *calling* the function (`themes.get_dropdown({})`), not by passing the function itself.

## Common Pitfalls

| Pitfall | Solution |
|---------|----------|
| Custom picker ignores user's fzf-native sorter | Pull from `conf.generic_sorter(opts)` / `conf.file_sorter(opts)`, not `sorters.get_fzy_sorter()` |
| Default mappings vanish after adding one | `attach_mappings` must `return true` — bare `function ... end` returns `nil` ⇒ `false` |
| Action fires but picker stays open | Call `actions.close(prompt_bufnr)` inside `:replace(fn)` — replacement skips the default close |
| `file_ignore_patterns = { "node_modules" }` hides LSP results too | Set ignore patterns per-picker (`pickers.find_files.file_ignore_patterns`), not in `defaults` |
| `live_grep` shows nothing despite matches | Check `vimgrep_arguments` includes `--column` and `--with-filename`; remove any color flags |
| Multi-select ignored on `<CR>` | Read `picker:get_multi_selection()` first; fall back to `action_state.get_selected_entry()` |
| Custom previewer never runs | Confirm `previewer = ...` is set (not `false`); global `preview = false` requires per-picker opt-in |
| `entry.value` is `nil` in the action | Your `entry_maker` returned `display`/`ordinal` only — `value` is required |
| `load_extension("fzf")` errors with "not found" | Native build step skipped. Re-run `make` in `telescope-fzf-native.nvim` or use its lazy `build = "make"` |
| Themes appear unapplied | You assigned the function rather than calling it: `themes.get_dropdown` vs `themes.get_dropdown({})` |
| Entries don't sort the way you expect | `ordinal` is the sort key — `display` is cosmetic. Set `ordinal` to the searchable string |
| Picker reopens with stale results after edits | Use `builtin.resume()` deliberately; for live data set `finders.new_job` (per-keystroke re-run) |
| `vim.ui.select` still uses native UI | `ui-select` extension not loaded, or loaded before `setup` — order matters |
| Slow first-render with thousands of entries | Use `display = function(e) ... end` for deferred rendering and tune `cache_picker` |

## References

- `~/.local/share/nvim/lazy/telescope.nvim/doc/telescope.txt` — primary help (`:help telescope`)
- `~/.local/share/nvim/lazy/telescope.nvim/developers.md` — custom picker / extension tutorial
- `~/.local/share/nvim/lazy/telescope.nvim/lua/telescope/config.lua` — every default option, with inline docstrings
- `~/.local/share/nvim/lazy/telescope.nvim/lua/telescope/builtin/init.lua` — builtin picker registry
- `~/.local/share/nvim/lazy/telescope.nvim/lua/telescope/actions/init.lua` — actions and `:replace`/`:enhance`
- `~/.local/share/nvim/lazy/telescope.nvim/lua/telescope/make_entry.lua` — entry metatables and helpers
- `~/.local/share/nvim/lazy/telescope.nvim/lua/telescope/themes.lua` — dropdown / cursor / ivy
- `~/.local/share/nvim/lazy/telescope.nvim/lua/telescope/pickers/entry_display.lua` — multi-column displayer
- `:help telescope.setup` / `:help telescope.builtin` / `:help telescope.actions` — in-editor authoritative reference

Project-specific keymap and picker wiring lives in `lua/plugins/navigation.lua` and `lua/config/keymaps.lua`. This skill is general telescope. For Neovim-side concerns (autocmds, LSP integration) use the `neovim` skill; for module structure use `lua`.
