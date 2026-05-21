---
name: nvim-expert
description: Expert on Neovim itself — its API surface, runtime model, and ecosystem. Use when writing, reviewing, debugging, or explaining Neovim plugin or config code, regardless of project conventions. Covers buffers/windows/tabs, autocmds, keymaps, options, the LSP client, diagnostics, treesitter, extmarks/namespaces, floating windows, vim.loop/vim.uv (libuv), vim.schedule semantics, RPC, and the differences between vim.api/vim.fn/vim.cmd/ex commands. Triggers, any question about how Neovim works, `:help` lookups, "why doesn't this autocmd fire", LSP handler customization, extmark vs sign, async patterns in nvim, plugin lazy loading.
---

# Neovim Expert

Authoritative reference for Neovim's runtime and API. Scope is the editor itself — not any particular distribution (NvChad, LazyVim, etc.) or plugin manager.

## Runtime model in one paragraph

Neovim is a single-threaded event loop (libuv) running an embedded Lua 5.1/LuaJIT interpreter alongside the legacy Vim core. The main loop processes input, executes autocommands, and drains a queue of scheduled callbacks. Plugins are Lua/Vimscript files discovered via `'runtimepath'`. The **API** (`vim.api.nvim_*`) is the stable, RPC-exposed surface; the **Ex commands** and **Vimscript functions** (`vim.fn.*`) are the legacy surface. Most modern code uses the `vim.*` Lua wrappers.

## The five ways to talk to Neovim from Lua

| Surface          | Example                                  | When                                |
|------------------|------------------------------------------|-------------------------------------|
| `vim.api.*`      | `vim.api.nvim_buf_set_lines(0, …)`       | First choice. Stable, fast, typed.  |
| `vim.fn.*`       | `vim.fn.expand("%:p")`                   | Vimscript functions with no API equivalent. |
| `vim.cmd(...)`   | `vim.cmd("write")` / `vim.cmd.write()`   | Ex commands. `vim.cmd.x{args, bang=true}` is the Lua-native form. |
| `vim.opt.*`      | `vim.opt.number = true`                  | Options. Handles list/dict-style values. |
| `vim.keymap.set` | `vim.keymap.set("n", "<C-s>", "<cmd>w<CR>")` | Keymaps with Lua callbacks. |

Avoid `vim.cmd("...")` with interpolated user data — quote/escape via `vim.fn.fnameescape` etc., or use the API directly.

## Buffers, windows, tabs

Three independent handles:
- **buffer** — text + per-buffer state (filetype, options, marks, extmarks).
- **window** — viewport into a buffer; has cursor position, options, dimensions.
- **tabpage** — collection of windows in a layout.

```lua
vim.api.nvim_get_current_buf()       -- 0 is also "current buffer" in most APIs
vim.api.nvim_get_current_win()
vim.api.nvim_get_current_tabpage()

vim.api.nvim_list_bufs()             -- all buffers including unloaded
vim.api.nvim_buf_is_loaded(buf)
vim.api.nvim_buf_is_valid(buf)
```

Reading/writing buffer content:
```lua
local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
vim.api.nvim_buf_set_lines(buf, start, end_, strict_indexing, replacement)
-- For partial-line edits:
vim.api.nvim_buf_set_text(buf, sr, sc, er, ec, lines)
```

Line indexing is **0-based, end-exclusive** in the API. Column indexing is **0-based byte offsets** (not characters, not display columns). Compare with `vim.fn.line()`/`col()` which are **1-based**, and `vim.fn.virtcol()` which is **display column**.

Cursor: `vim.api.nvim_win_get_cursor(win)` returns `{row(1-based), col(0-based)}`. The asymmetry is historical — memorize it.

Scratch buffer:
```lua
local buf = vim.api.nvim_create_buf(false, true)   -- listed=false, scratch=true
vim.bo[buf].bufhidden = "wipe"
```

## Options

Three scopes: global, buffer-local, window-local. Some options exist in multiple scopes (`buftype` is buffer-local, `wrap` is window-local, `mouse` is global).

```lua
vim.o.number = true             -- get/set, all scopes via fallback
vim.go.x = …                    -- global only
vim.bo[buf].filetype = "lua"    -- buffer-local
vim.wo[win].wrap = false        -- window-local

vim.opt.listchars = { tab = "» ", trail = "·" }   -- handles dict/list options
vim.opt.path:append("**")                          -- list helpers
vim.opt_local.spell = true                         -- :setlocal
vim.opt_global.shell = "/bin/zsh"                  -- :setglobal
```

`vim.opt` returns an `Option` object with `:get()`, `:set()`, `:append()`, `:prepend()`, `:remove()`. Use `:get()` (not the option directly) when you need the raw value.

## Autocommands

Event-driven hooks. Always group them — ungrouped autocmds accumulate on `:source`.

```lua
local group = vim.api.nvim_create_augroup("MyGroup", { clear = true })

vim.api.nvim_create_autocmd("BufWritePre", {
  group = group,
  pattern = { "*.lua", "*.py" },
  callback = function(args)
    -- args = { id, event, group, match, buf, file, data }
  end,
})
```

Common events: `BufRead`, `BufReadPost`, `BufWritePre`, `BufWritePost`, `BufEnter`, `BufLeave`, `BufHidden`, `BufUnload`, `BufDelete`, `BufWipeout`, `FileType`, `VimEnter`, `VimLeave`, `UIEnter`, `WinEnter`, `WinLeave`, `WinResized`, `CursorMoved`, `CursorMovedI`, `TextChanged`, `TextChangedI`, `InsertEnter`, `InsertLeave`, `ModeChanged`, `LspAttach`, `LspDetach`, `DiagnosticChanged`, `User` (custom).

Trigger manually: `vim.api.nvim_exec_autocmds("User", { pattern = "MyEvent", data = {…} })`.

Gotchas:
- `FileType` fires *after* the buffer is loaded and ftplugin has run. To set options that should win, use a `FileType` autocmd, not a ftplugin file you don't control.
- `BufReadPost` fires before `FileType`. `BufEnter` fires every time the buffer is entered, including on tab switches.
- Setting buffer-local options inside a `BufNew` callback may fire before the buffer is "real" — prefer `BufReadPost` or `FileType`.
- `pattern` matches the file path for buffer events; for filetype-scoped use `pattern = "lua"` with a `FileType` event, not a `BufRead` event.

## Keymaps

```lua
vim.keymap.set({ "n", "x" }, "<leader>y", '"+y', { desc = "Yank to clipboard" })

vim.keymap.set("n", "<leader>f", function()
  require("telescope.builtin").find_files()
end, { silent = true, buffer = 0 })   -- buffer=0 → current buffer
```

Options: `silent`, `noremap` (default true), `expr`, `nowait`, `buffer`, `desc`, `remap`. `desc` is critical for which-key/help.

Modes: `n` normal, `i` insert, `v` visual+select, `x` visual only, `s` select only, `o` operator-pending, `c` cmdline, `t` terminal, `!` insert+cmdline, `""` (empty) normal+visual+operator-pending.

`<cmd>…<CR>` runs an Ex command without leaving the current mode (unlike `:…<CR>`, which exits visual). Prefer for keymaps that should preserve mode/selection.

`expr=true` evaluates the RHS as an expression returning the keys to feed. Common for `<expr>` mappings like `<Tab>` completion logic.

Delete with `vim.keymap.del("n", "<leader>x", { buffer = 0 })`.

## User commands

```lua
vim.api.nvim_create_user_command("Greet", function(opts)
  -- opts = { name, args, fargs, bang, line1, line2, range, count, mods, smods, reg }
  print("hi " .. opts.args)
end, {
  nargs = "?",                  -- 0|1|"*"|"?"|"+"
  range = true,                 -- accepts a line range
  bang = true,                  -- accepts !
  complete = "file",            -- or a function(arglead, cmdline, cursorpos)
  desc = "Say hi",
})
```

Buffer-local: `vim.api.nvim_buf_create_user_command(buf, …)`.

## Highlights, namespaces, extmarks

**Highlight groups** style ranges of text.
```lua
vim.api.nvim_set_hl(0, "MyGroup", { fg = "#ff8800", bold = true })
vim.api.nvim_set_hl(0, "MyLink", { link = "Comment" })
```

`0` is the global namespace; passing a real namespace makes the highlight window-local via `nvim_win_set_hl_ns`.

**Namespaces** are integer scopes used by extmarks, diagnostics, virtual text, and window highlights:
```lua
local ns = vim.api.nvim_create_namespace("my.plugin")
```

**Extmarks** mark a position (or range) that survives edits.
```lua
local id = vim.api.nvim_buf_set_extmark(buf, ns, row, col, {
  end_row = row, end_col = col + 5,
  hl_group = "Search",
  virt_text = { { " ← here", "Comment" } },
  virt_text_pos = "eol",        -- "overlay" | "right_align" | "inline" (0.10+) | "eol"
  virt_lines = { { { "above this line", "Comment" } } },
  virt_lines_above = true,
  sign_text = "▶",
  sign_hl_group = "WarningMsg",
  conceal = "·",
  hl_mode = "combine",          -- "combine" | "replace" | "blend"
  priority = 100,
  right_gravity = true,         -- whether the mark moves right or stays when text is inserted
})

vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
```

Extmarks replaced signs and matchadd-style highlights. Use them for: diagnostics underlines, gutter signs, inline hints, code lenses, blame text, ghost text.

## Floating windows

```lua
local buf = vim.api.nvim_create_buf(false, true)
local win = vim.api.nvim_open_win(buf, true, {   -- enter=true
  relative = "editor",          -- "editor" | "win" | "cursor" | "mouse"
  width = 60, height = 10,
  row = 5, col = 10,
  border = "rounded",           -- "none"|"single"|"double"|"rounded"|"solid"|"shadow"|custom array
  style = "minimal",            -- strips signcolumn, number, etc.
  title = " Hello ", title_pos = "center",
  footer = "─ 1/2 ─", footer_pos = "right",
  zindex = 50,
  focusable = true,
  noautocmd = true,             -- skip BufEnter/WinEnter etc.
})
```

Update: `vim.api.nvim_win_set_config(win, { relative = …, … })`. Close: `vim.api.nvim_win_close(win, force)`.

`style = "minimal"` resets a bunch of options inside the float. Set `vim.wo[win].winhighlight = "Normal:MyFloat,FloatBorder:MyBorder"` to scope colors.

## LSP client

The built-in client (`vim.lsp`) is **not** a plugin — it's part of core. Plugins like `nvim-lspconfig` just provide canned `start` configurations.

Starting a server manually:
```lua
vim.lsp.start({
  name = "myls",
  cmd = { "my-language-server" },
  root_dir = vim.fs.root(0, { ".git", "package.json" }),
  capabilities = vim.lsp.protocol.make_client_capabilities(),
  settings = { …server-specific… },
  on_attach = function(client, bufnr) … end,
})
```

`vim.lsp.start` deduplicates by `name`+`root_dir`. It attaches the current buffer; subsequent matching buffers attach automatically via `FileType`.

Client lifecycle:
- `vim.lsp.get_clients({ bufnr = 0 })` — clients attached to buffer.
- `vim.lsp.buf_attach_client(bufnr, client_id)` / `buf_detach_client`.
- `vim.lsp.stop_client(id, force)` — terminate.

Server requests:
```lua
vim.lsp.buf.definition()              -- jumps
vim.lsp.buf.hover()                   -- floats
vim.lsp.buf.references()
vim.lsp.buf.rename()
vim.lsp.buf.code_action()
vim.lsp.buf.format({ async = true })
vim.lsp.buf.document_symbol()
vim.lsp.buf.workspace_symbol("Foo")
```

Custom requests:
```lua
local clients = vim.lsp.get_clients({ bufnr = 0 })
clients[1].request("textDocument/hover", params, function(err, result, ctx)
  -- handler
end, 0)
```

Override handlers (0.10 deprecates `vim.lsp.handlers[m]` mutation in favor of `vim.lsp.handlers[m]` still working but `client.handlers[m]` preferred):
```lua
vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics,
  { virtual_text = false, signs = true }
)
```

Events: `LspAttach`, `LspDetach`, `LspProgress`, `LspNotify`, `LspRequest`, `LspTokenUpdate` (semantic tokens).

Capabilities: enrich with `cmp_nvim_lsp.default_capabilities()` (nvim-cmp) or set `textDocument.completion.completionItem.snippetSupport = true` manually.

## Diagnostics

A buffer-level, namespace-keyed list of structured warnings/errors. Used by LSP but usable by any source (linters, custom checks).

```lua
local ns = vim.api.nvim_create_namespace("my.linter")
vim.diagnostic.set(ns, bufnr, {
  {
    lnum = 0, end_lnum = 0,
    col = 4, end_col = 10,
    severity = vim.diagnostic.severity.WARN,   -- ERROR|WARN|INFO|HINT
    message = "unused variable",
    source = "my.linter",
    code = "W001",
  },
})

vim.diagnostic.config({
  virtual_text = { prefix = "●", spacing = 4 },
  virtual_lines = false,              -- 0.10+ for multi-line
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = { border = "rounded", source = true },
})

vim.diagnostic.open_float()
vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR })  -- 0.11+
-- legacy: vim.diagnostic.goto_next()/goto_prev()
```

## Treesitter

Built-in incremental parser. Parsers are installed externally (commonly via `nvim-treesitter`).

```lua
vim.treesitter.start(bufnr, "lua")   -- enables highlighting using queries

local parser = vim.treesitter.get_parser(bufnr, "lua")
local tree = parser:parse()[1]
local root = tree:root()

local query = vim.treesitter.query.parse("lua", [[
  (function_declaration name: (identifier) @fn.name)
]])

for id, node, metadata in query:iter_captures(root, bufnr, 0, -1) do
  local name = query.captures[id]   -- "fn.name"
  local text = vim.treesitter.get_node_text(node, bufnr)
end
```

Folds: `set foldmethod=expr foldexpr=v:lua.vim.treesitter.foldexpr()` (0.10+).
Indent: `set indentexpr=v:lua.require'nvim-treesitter'.indentexpr()` (via plugin).

Predicates in queries: `(#eq? @x "foo")`, `(#match? @x "%.lua$")`, `(#any-of? @x "a" "b")`. Custom directives can be registered via `vim.treesitter.query.add_directive`.

## Async, the event loop, and `vim.schedule`

Neovim is single-threaded. "Async" means yielding back to the event loop. Most API calls are **fast-context-safe**: callable from any callback. But some operations (touching buffers from libuv callbacks) require returning to the main loop via `vim.schedule`.

```lua
vim.uv.new_timer():start(0, 0, vim.schedule_wrap(function()
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "hi" })
end))
```

- `vim.schedule(fn)` — defer until safe to call any API. Use inside libuv callbacks.
- `vim.schedule_wrap(fn)` — returns a wrapper that schedules `fn`.
- `vim.defer_fn(fn, ms)` — schedule after a delay (timer + schedule).
- `vim.wait(timeout, predicate, interval, fast_only)` — pump the loop until predicate true or timeout. Use sparingly; blocks input.

**libuv via `vim.uv`** (alias `vim.loop` deprecated in favor of `vim.uv` in 0.10+):
```lua
local handle
handle = vim.uv.spawn("rg", {
  args = { "--vimgrep", "TODO" },
  stdio = { nil, stdout, stderr },
}, vim.schedule_wrap(function(code, signal)
  handle:close()
end))

vim.uv.read_start(stdout, vim.schedule_wrap(function(err, data)
  if data then … end
end))
```

`vim.system` (0.10+) is a higher-level wrapper:
```lua
vim.system({ "rg", "TODO" }, { text = true }, function(obj)
  -- obj = { code, signal, stdout, stderr }
  vim.schedule(function() print(obj.stdout) end)
end)
-- or sync:
local result = vim.system({ "echo", "hi" }, { text = true }):wait()
```

## RPC, remote control, headless

Neovim can be controlled over MsgPack-RPC via stdio or a socket:

```bash
nvim --headless --listen /tmp/nvim.sock
nvim --headless +"luafile script.lua" +qa
```

```lua
local chan = vim.fn.sockconnect("pipe", "/tmp/nvim.sock", { rpc = true })
vim.rpcrequest(chan, "nvim_buf_get_lines", 0, 0, -1, false)
vim.rpcnotify(chan, "nvim_input", "iHello<Esc>")
```

`channels` also wrap job stdio, terminal, and embedded UI. Use `vim.fn.jobstart` for legacy jobs or `vim.uv.spawn`/`vim.system` for new code.

## Filetype detection

Three layers, in priority order:
1. `vim.filetype.add({ extension = …, filename = …, pattern = … })` — Lua-based, fastest.
2. `ftdetect/*.vim` files in runtimepath.
3. Built-in `filetype.lua` rules.

```lua
vim.filetype.add({
  extension = { foo = "lua" },
  filename = { ["Brewfile"] = "ruby" },
  pattern = {
    [".*/templates/.*%.html"] = "htmldjango",
    [".*/.github/workflows/.*"] = "yaml.github",   -- dotted filetypes
  },
})
```

Dotted filetypes (`yaml.github`) inherit from `yaml` for syntax/ftplugin purposes but allow more specific matching.

## Runtime paths & `:runtime`

`'runtimepath'` is a comma-separated list of directories searched for `plugin/`, `ftplugin/`, `syntax/`, `colors/`, `after/`, `lua/`, `queries/`, etc. `:runtime path/to/file.vim` sources the first match. `:runtime!` sources all matches.

Lua module search: `package.path` is set to include `<rtp>/lua/?.lua` and `<rtp>/lua/?/init.lua` for each entry. So `require("foo.bar")` finds `<any-rtp>/lua/foo/bar.lua`.

`after/` directories are loaded last, useful for overriding plugin defaults.

## Plugin loading models

Built-in: every file in `<rtp>/plugin/` is sourced at startup, every `ftplugin/<ft>/*.{vim,lua}` on filetype detection.

Modern plugin managers (lazy.nvim, packer, mini.deps) implement **lazy loading** on top:
- `event = "VeryLazy"` (lazy.nvim convention; fires after `UIEnter`).
- `ft = "lua"` — load on filetype.
- `cmd = "Telescope"` — load on first command call.
- `keys = "<leader>f"` — load on first keypress.
- `dependencies` — graph for ordering.

If you write plugin code yourself, **don't** assume a manager. Use `vim.api.nvim_create_autocmd`, `vim.keymap.set`, and `vim.api.nvim_create_user_command` directly. Lazy loaders trigger fine as long as you don't call into other plugins eagerly.

## Common gotchas

1. **0-based vs 1-based**: API is 0-based; `vim.fn`/Vimscript is 1-based; `nvim_win_get_cursor` is `{1-based row, 0-based col}`. Pin this down before any cursor math.
2. **Column is bytes**: a multibyte character occupies multiple columns. Use `vim.str_utfindex`/`vim.str_byteindex` to convert. `nvim_buf_get_text` is byte-based; treesitter is byte-based.
3. **`:redrawstatus`** is needed after setting `'statusline'` programmatically in some contexts.
4. **`vim.notify`** is overridable (`vim.notify = require("notify")`). Don't `print` for user messages.
5. **`vim.cmd("normal x")`** respects user remaps. Use `vim.cmd("normal! x")` (or `vim.cmd.normal{"x", bang=true}`) to bypass.
6. **`feedkeys`**:
   - `nvim_feedkeys(keys, mode, escape_ks)` — `mode` is a string of flags: `n` no-remap, `m` remap, `t` typed, `i` insert (at beginning), `x` execute immediately.
   - `vim.fn.feedkeys(keys, "n")` differs subtly. Read `:h feedkeys` before choosing.
   - Use `nvim_replace_termcodes("<CR>", true, false, true)` to translate `<CR>` etc.
7. **`expand("%")` returns the buffer name**, not the file. For a saved file's absolute path use `vim.api.nvim_buf_get_name(0)` or `vim.fn.expand("%:p")`.
8. **`vim.system` callback runs in fast event context** — wrap UI calls in `vim.schedule`.
9. **Augroup `clear = true`** wipes ALL autocmds in that group, including those from other places using the same name. Pick unique group names.
10. **Calling LSP methods on detached buffers** silently no-ops. Check `vim.lsp.get_clients({ bufnr = 0 })` first.
11. **`vim.tbl_deep_extend`** has three behavior modes: `"force"`, `"keep"`, `"error"`. List-valued keys are **not concatenated** — they're replaced wholesale. Use `vim.list_extend` for arrays.
12. **`vim.deepcopy`** can't copy functions with upvalues meaningfully. It copies tables and primitives; functions are passed by reference.
13. **`:lua print(…)`** goes to the message area; **`:=` (`:lua =…`)** pretty-prints, useful for inspection.
14. **`vim.inspect(x)`** pretty-prints tables. `vim.print(x)` (0.10+) is equivalent.
15. **Window options leak**: when you `:split`, the new window inherits window-local options from the old one. Use `vim.api.nvim_open_win` with explicit options for isolation.
16. **Setting `'filetype'` triggers `FileType`** every time it's set, even to the same value — guard with `if vim.bo.filetype ~= ft then`.
17. **`vim.b`/`vim.w`/`vim.t`** are per-buffer/window/tabpage variable tables. `vim.g` is global. Survives across config reloads (they're Vim variables).
18. **`vim.cmd` returns nothing** — to capture output use `vim.api.nvim_exec2(cmd, { output = true })`.

## Useful internal helpers

- `vim.fs.root(start, markers)` — find project root by markers.
- `vim.fs.find(needle, opts)` — `vim.fn.findfile` replacement.
- `vim.fs.normalize(path)` — expand `~`, normalize separators.
- `vim.iter(x)` (0.10+) — iterator API: `:filter`, `:map`, `:totable`, `:fold`.
- `vim.text` (0.10+) — text utilities.
- `vim.ui.input`/`vim.ui.select` — overridable input prompts.
- `vim.validate({ x = { x, "string" } })` — argument validation.
- `vim.tbl_*` — `keys`, `values`, `contains`, `count`, `isempty`, `filter`, `map`, `flatten`, `extend`, `deep_extend`, `get`.
- `vim.split(s, sep, opts)` / `vim.gsplit` — string split, lazy variant.

## Helpful `:help` tags to know exist

`:h api`, `:h lua-guide`, `:h vim.api`, `:h lsp`, `:h lsp-handler`, `:h treesitter`, `:h extmark`, `:h autocmd-events`, `:h fast-event-loop`, `:h luaeval`, `:h channel`, `:h api-buffer-updates`, `:h options`, `:h winhighlight`.

When in doubt, read `:help`. The bundled docs are the source of truth — every API function and event is documented there with the exact arg shapes Neovim accepts.
