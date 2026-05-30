---
name: neovim
description: Apply Neovim-specific API knowledge when writing or modifying Lua code that calls the editor — `vim.api`, `vim.fn`, autocmds, keymaps, buffers/windows/tabs, options, LSP (`vim.lsp`), diagnostics (`vim.diagnostic`), treesitter (`vim.treesitter`), filetype detection, `vim.uv`/`vim.system`, UI events, highlight groups, user commands. Use whenever a task touches Neovim's runtime surface (anywhere `vim.*` appears) so the result picks the right namespace, follows event-loop rules, and matches modern (0.10+) conventions instead of legacy Vimscript translations.
---

# Neovim

Editor-level guidance for working against Neovim's Lua runtime: which namespace to call, how to register autocmds and keymaps cleanly, when to dispatch off the main loop, and how to use the built-in LSP / diagnostic / treesitter modules. This skill complements the `lua` skill — that one covers the language; this one covers the host.

Target version: **Neovim 0.10+** (current stable line at time of writing). When unsure about a function's availability, run `:help <name>` locally or read the help topic listed in [References](#references) — those files ship with the runtime and are authoritative.

## When to Use

- Any code calling `vim.*` (api, fn, lsp, diagnostic, treesitter, uv, keymap, ...).
- Adding or refactoring autocmds, user commands, keymaps, options.
- Wiring up an LSP client config, on_attach handler, or capabilities table.
- Async work: scheduling onto the main loop, spawning processes, watching files.
- Buffer / window / tabpage manipulation: creation, scratch buffers, floats.
- Filetype detection, syntax/treesitter integration, highlight groups.
- Plugin specs in `lua/plugins/` whose `config` function actually touches the editor.

## When Not to Use

- Pure Lua refactors with no `vim.*` calls → use the `lua` skill.
- Lazy.nvim spec mechanics (event/ft/cmd/keys/opts shape) → those are conventions, not Neovim API.
- Editing user-facing config like `chadrc.lua` or `options.lua` where the right value is obvious.

## Decision Map: Which Namespace

| You want to... | Use |
|----------------|-----|
| Set an option globally | `vim.opt.<name>` (list-like options) or `vim.o.<name>` (scalars) |
| Set a buffer/window-local option | `vim.bo[buf].<name>`, `vim.wo[win].<name>` |
| Read/write a variable | `vim.g`, `vim.b`, `vim.w`, `vim.t`, `vim.v` |
| Call a Vimscript function | `vim.fn.<name>(...)` |
| Run an Ex command | `vim.cmd.colorscheme("habamax")` (preferred) or `vim.cmd("colorscheme habamax")` |
| Low-level editor primitives | `vim.api.nvim_*` |
| Create a keymap | `vim.keymap.set(mode, lhs, rhs, opts)` |
| Create an autocmd | `vim.api.nvim_create_autocmd(event, opts)` with `group =` |
| Create a user command | `vim.api.nvim_create_user_command(name, fn, opts)` |
| Notify the user | `vim.notify(msg, vim.log.levels.WARN)` |
| Schedule work on the main loop | `vim.schedule(fn)` or `vim.schedule_wrap(fn)` |
| Spawn a process | `vim.system({cmd, args}, {opts}, on_exit)` (modern) — not `jobstart` |
| Filesystem / event loop | `vim.uv.*` (was `vim.loop` pre-0.10) |
| LSP | `vim.lsp.*` and `vim.lsp.config()` / `vim.lsp.enable()` (0.11+) |
| Diagnostics | `vim.diagnostic.*` |
| Treesitter | `vim.treesitter.*` and `vim.treesitter.query.*` |
| Filetype | `vim.filetype.add({ extension = {...}, filename = {...}, pattern = {...} })` |

**`vim.api` vs `vim.fn`**: `vim.api.*` is the C API surface — fast, stable, takes/returns Lua values. `vim.fn.*` shells into Vimscript builtins — slower, returns Vimscript types. Prefer `vim.api` when both exist.

## Core Patterns

### Autocmds with groups (always)

```lua
local group = vim.api.nvim_create_augroup("MyFeature", { clear = true })

vim.api.nvim_create_autocmd("BufWritePre", {
  group = group,
  pattern = { "*.lua", "*.py" },
  callback = function(args)
    -- args.buf, args.file, args.match, args.data
  end,
  desc = "Strip trailing whitespace before write",
})
```

Rules:

- **Always** pass a `group`. Anonymous autocmds duplicate on `:source`/`:Lazy reload`.
- Use `callback` (Lua function), not `command` (Vimscript string).
- Set `desc` — it shows in `:autocmd` and helps debugging.
- The callback receives a table; destructure only what you need.
- Return `true` from the callback to delete the autocmd (one-shot pattern).

### Keymaps

```lua
vim.keymap.set("n", "<leader>w", "<cmd>write<cr>", {
  desc = "Save buffer",
  silent = true,
})

-- Buffer-local:
vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = bufnr, desc = "LSP hover" })

-- Expression mapping:
vim.keymap.set("i", "<Tab>", function()
  return vim.fn.pumvisible() == 1 and "<C-n>" or "<Tab>"
end, { expr = true })
```

Rules:

- Prefer Lua callbacks over `<cmd>...<cr>` strings when logic is non-trivial.
- Always set `desc` — which-key and `:Telescope keymaps` rely on it.
- `silent = true` for keymaps that would otherwise echo a command.
- For plugin-spec keys, use the lazy.nvim `keys = { ... }` form so it lazy-loads the plugin.

### User commands

```lua
vim.api.nvim_create_user_command("Foo", function(opts)
  -- opts.args, opts.fargs, opts.bang, opts.line1, opts.line2, opts.count, opts.range
end, {
  nargs = "?",
  range = true,
  desc = "Do the foo thing",
  complete = function(_, _, _) return { "a", "b", "c" } end,
})
```

Buffer-local commands: `vim.api.nvim_buf_create_user_command(bufnr, ...)`.

### Options

```lua
vim.opt.shiftwidth = 2          -- canonical
vim.opt.listchars:append("tab:» ")
vim.opt.formatoptions:remove("o")

vim.bo[bufnr].filetype = "lua"  -- buffer-local
vim.wo[winid].number = true     -- window-local
```

- `vim.opt.<name>` returns a wrapper object — supports `:append`, `:remove`, `:prepend` on list-like options.
- `vim.o.<name>` is the raw scalar; use it when you don't need the wrapper.
- Don't use `vim.cmd("set ...")` — slower and no Lua-side validation.

### Buffers, windows, tabs

```lua
-- Scratch buffer:
local buf = vim.api.nvim_create_buf(false, true)  -- listed=false, scratch=true
vim.bo[buf].bufhidden = "wipe"
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "hello" })

-- Floating window:
local win = vim.api.nvim_open_win(buf, true, {
  relative = "editor",
  width = 60, height = 10,
  row = 5, col = 10,
  style = "minimal",
  border = "rounded",
})
```

Handle rules:

- Always check `vim.api.nvim_buf_is_valid(buf)` before operating on a stored handle — buffers can be wiped between events.
- `0` means "current buffer/window/tab" in most API calls.
- `nvim_buf_set_lines` indices are 0-based, end-exclusive (Python-style). `nvim_win_set_cursor` is `{row, col}` with **1-based row, 0-based col** — the only place this asymmetry shows up. `:help api-indexing`.

### Async on the event loop

The Lua runtime has one main loop. Most `vim.api.*` calls are **not** safe from a `vim.uv` callback — you must hop back.

```lua
vim.uv.fs_stat(path, function(err, stat)
  vim.schedule(function()
    -- Safe to call vim.api.* here
    vim.notify(stat and "ok" or err)
  end)
end)
```

For spawning processes prefer `vim.system` (0.10+) over `vim.fn.jobstart`:

```lua
vim.system({ "rg", "--json", pattern }, { text = true }, function(obj)
  vim.schedule(function()
    -- obj.code, obj.stdout, obj.stderr
  end)
end)
```

`vim.schedule_wrap(fn)` returns a wrapped version useful for callback-passing APIs.

### LSP (modern surface)

For 0.11+ prefer the declarative `vim.lsp.config` + `vim.lsp.enable`:

```lua
vim.lsp.config("lua_ls", {
  settings = { Lua = { diagnostics = { globals = { "vim" } } } },
})
vim.lsp.enable("lua_ls")
```

For 0.10 (and older nvim-lspconfig setups), `require("lspconfig").lua_ls.setup({...})` still works.

`on_attach` pattern (one autocmd, not per-server):

```lua
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspAttach", { clear = true }),
  callback = function(args)
    local bufnr = args.buf
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client:supports_method("textDocument/definition") then
      vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = bufnr })
    end
  end,
})
```

Capabilities for nvim-cmp / blink.cmp: get from the completion plugin and pass once globally, do not hardcode.

### Diagnostics

```lua
vim.diagnostic.config({
  virtual_text = { prefix = "●" },
  severity_sort = true,
  float = { border = "rounded" },
})

vim.diagnostic.set(ns, bufnr, {
  { lnum = 0, col = 0, message = "...", severity = vim.diagnostic.severity.WARN },
})
```

- Namespaces are integers from `vim.api.nvim_create_namespace("name")`. Cache them per-module.
- `vim.diagnostic` is independent of LSP — usable from any source (linters, custom checks).

### Treesitter

```lua
local parser = vim.treesitter.get_parser(bufnr, "lua")
local tree = parser:parse()[1]
local root = tree:root()

local query = vim.treesitter.query.parse("lua", [[
  (function_declaration name: (identifier) @name)
]])

for _, node, _ in query:iter_captures(root, bufnr, 0, -1) do
  local text = vim.treesitter.get_node_text(node, bufnr)
end
```

- Don't shell to external parsers — use `vim.treesitter.*`.
- For highlight groups, define captures in `queries/<lang>/highlights.scm` in your runtimepath rather than calling the highlight API per-node.

### Filetype detection

```lua
vim.filetype.add({
  extension = { foo = "foo" },
  filename = { ["Brewfile"] = "ruby" },
  pattern = {
    [".*/hypr/.*%.conf"] = "hyprlang",
    [".*"] = {
      function(path, bufnr)
        if vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]:match("^#!.*python") then
          return "python"
        end
      end,
      { priority = -math.huge },
    },
  },
})
```

Three keys: `extension`, `filename`, `pattern`. Avoid `BufRead` autocmds for filetype — that's what `vim.filetype.add` exists for.

### Highlight groups

```lua
vim.api.nvim_set_hl(0, "MyGroup", { fg = "#ff0000", bg = "NONE", bold = true })
```

- Namespace `0` is the global namespace.
- Link instead of duplicate: `vim.api.nvim_set_hl(0, "MyGroup", { link = "DiagnosticError" })`.
- Set highlights on `ColorScheme` autocmd so they survive `:colorscheme` changes.

### Notifications

```lua
vim.notify("done", vim.log.levels.INFO)
```

Don't `print()` for user-visible messages — it bypasses notification plugins (snacks, fidget, etc.) the user may have configured.

## Event Loop & Threading Cheatsheet

| Context | Safe to call `vim.api`? |
|---------|-------------------------|
| Main Lua thread (most code) | ✅ |
| Autocmd / keymap / user command callback | ✅ |
| `vim.schedule(fn)` body | ✅ |
| `vim.uv.*` callback | ❌ — wrap with `vim.schedule` |
| `vim.system` `on_exit` callback | ❌ — wrap with `vim.schedule` |
| LSP handler | ✅ (already scheduled) |
| Coroutine via `coroutine.resume` | depends — `vim.schedule_wrap` your resume |

When in doubt: `vim.schedule(function() ... end)`. The cost is one event-loop tick.

## Workflow

### Step 1: Identify the surface

Before writing, ask: which `vim.*` does this need? Check the Decision Map above. If unsure, `:help vim.<area>` in a running Neovim.

### Step 2: Pick the modern path

Many tasks have a legacy way (Vimscript translation) and a modern way:

| Don't | Do |
|-------|-----|
| `vim.cmd("autocmd ...")` | `vim.api.nvim_create_autocmd` |
| `vim.cmd("nnoremap ...")` | `vim.keymap.set("n", ...)` |
| `vim.cmd("set ...")` | `vim.opt.<name> = ...` |
| `vim.fn.jobstart(...)` | `vim.system({...}, ..., on_exit)` |
| `vim.loop` | `vim.uv` |
| `print(msg)` | `vim.notify(msg, level)` |
| `:command! Foo ...` in vimscript | `vim.api.nvim_create_user_command("Foo", fn, {})` |
| `b:variable` via cmd | `vim.b[bufnr].variable` |

### Step 3: Group and describe

Every autocmd gets a group. Every keymap and user command gets a `desc`. Future-you and `:checkhealth` will thank you.

### Step 4: Schedule when crossing boundaries

If your code path comes from `vim.uv`, `vim.system`, or a coroutine, wrap the editor-touching parts in `vim.schedule`. A `E5560: nvim_*_ must not be called in a fast event context` error means you forgot.

### Step 5: Validate

```bash
make fmt && make lint && make test
```

In a running Neovim: `:checkhealth` and `:messages` after exercising the code path.

## Validation

- [ ] Autocmds use `nvim_create_augroup({ clear = true })`.
- [ ] Keymaps and user commands have `desc`.
- [ ] No `vim.cmd("autocmd ...")`, `vim.cmd("nnoremap ...")`, or `vim.cmd("set ...")`.
- [ ] `vim.uv` / `vim.system` callbacks wrap editor calls in `vim.schedule`.
- [ ] LSP setup goes through `vim.lsp.config` (0.11+) or lspconfig (0.10), never raw `vim.lsp.start` unless you have a reason.
- [ ] Buffer/window handles checked with `nvim_*_is_valid` if held across event boundaries.
- [ ] Highlight definitions re-applied on `ColorScheme`.
- [ ] No `print()` for user-visible output — use `vim.notify`.

## Common Pitfalls

| Pitfall | Solution |
|---------|----------|
| `E5560: must not be called in a fast event context` | Wrap the offending block in `vim.schedule(function() ... end)` |
| Duplicate autocmds after `:source` | Always create an augroup with `{ clear = true }` and pass `group =` |
| Keymap doesn't fire | Check mode (`n`/`i`/`v`/`x`/`s`/`o`/`t`/`c`), `<leader>` timing, and that it's not shadowed (`:verbose map <lhs>`) |
| `vim.opt` vs `vim.o` confusion | `vim.opt` for list/set options (with `:append`/`:remove`); `vim.o` for scalars |
| 0-based vs 1-based indexing | API is 0-based end-exclusive; cursor row is 1-based. `:help api-indexing` |
| LSP `on_attach` doesn't fire | Switch to a single `LspAttach` autocmd; per-server `on_attach` is fragile |
| Filetype not detected | Use `vim.filetype.add`, not a `BufRead` autocmd |
| Highlight wiped after colorscheme change | Register on `ColorScheme` autocmd, not at startup |
| `vim.fn.<x>` slow in a loop | Check if `vim.api.nvim_*` or `vim.<x>` (e.g. `vim.fs.find`) exists |
| Stale buffer handle crashes | `if vim.api.nvim_buf_is_valid(buf) then ... end` before use |
| `vim.loop` deprecated warning | Rename to `vim.uv` — same API |
| Calling LSP method client doesn't support | `client:supports_method("textDocument/...")` first |

## References

Run `:help <topic>` for any of these — they are the source of truth:

- **`:help lua-guide`** — high-level Lua-in-Neovim intro
- **`:help lua`** — `vim.*` reference
- **`:help api`** — `vim.api.nvim_*` reference
- **`:help autocmd`** — events and `nvim_create_autocmd`
- **`:help map`** — keymap modes and `vim.keymap.set`
- **`:help options`** — every option
- **`:help lsp`** — built-in LSP client
- **`:help diagnostic`** — `vim.diagnostic`
- **`:help treesitter`** — `vim.treesitter` and queries
- **`:help filetype`** — detection
- **`:help luvref`** — `vim.uv` (libuv) reference
- **`:help vim.system`** — modern process spawning
- **`:help news`** — version-to-version changes; check before assuming an API exists
- **`:help vim_diff`** — Neovim vs. Vim differences

Online mirror: <https://neovim.io/doc/user/> — but local `:help` is faster and version-matched.

Project-specific guidance lives in `AGENTS.md`; this skill is general Neovim. For language-level Lua patterns (modules, OOP, perf), use the `lua` skill instead.
