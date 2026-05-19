---
name: lua-expert
description: Lua expert advisor for this Neovim config. Apply OOP (colon syntax, metatables, inheritance), low coupling, separation of concerns, and other idiomatic Lua patterns. Use when writing or refactoring Lua modules, designing class hierarchies, splitting large files, reviewing code quality, asking "how should I structure X in Lua", or any question touching Lua patterns, metatables, closures, iterators, error handling, or Neovim-specific Lua idioms.
argument-hint: [file-or-topic]
allowed-tools: [Read, Edit, Write, Bash, Glob, Grep]
---

# Lua Expert

Expert advisor for this Neovim config. Read referenced files in full before acting.

**Core principles:** reject invented abbreviations; prefer intention-revealing names over short ones; code reads like prose without needing comments.

---

## OOP — Module & Class Patterns

```lua
local M = {}
function M.greet(name) return "Hello, " .. name end  -- dot: no self
return M

local MyClass = {}
MyClass.__index = MyClass
function MyClass.new(opts)                            -- dot: constructor
  return setmetatable({ value = opts.value or 0 }, MyClass)
end
function MyClass:increment(by) self.value = self.value + (by or 1) end  -- colon: self

local Rect = setmetatable({}, { __index = Base })    -- inheritance
Rect.__index = Rect
function Rect.new(opts)
  local self = Base.new(opts)
  self.w, self.h = opts.w, opts.h
  return setmetatable(self, Rect)
end
```

Rule: `.` for constructors/pure functions; `:` for anything operating on `self`.

---

## Low Coupling

**Dependency injection:** accept deps as arguments; don't reach out with `require` inside functions.

**Late require:** wrap optional/heavy deps in `pcall(require, ...)` inside the function that needs them — never at module top-level.

**Module state:** consolidate all mutable upvalues into one `_state` table.
```lua
local _state = { ui = nil, ns = nil }   -- single source of truth; never scattered bare locals
```

**Circular requires:** extract the shared contract into a third module C, or use late require.

---

## Separation of Concerns

Split when a file exceeds ~200 lines with unrelated sections, or mixes state/logic/UI.

**Aggregator pattern:** `plugins/ui/init.lua` contains only `require` calls; all logic lives in sub-files.

| Layer  | Responsibility                    |
|--------|-----------------------------------|
| Config | Static values, thresholds, labels |
| State  | Runtime mutable data (`_state`)   |
| Logic  | Pure computation, transformations |
| UI     | Rendering, side effects, keymaps  |

---

## Metatables

Key metamethods: `__index` (inheritance/computed props), `__newindex` (read-only/proxy), `__call`, `__tostring`, `__eq`, `__lt`/`__le`, `__len`, `__concat`.

```lua
local proxy = setmetatable({}, {
  __index = function(t, k) local v = expensive_lookup(k); rawset(t, k, v); return v end,
})
```

---

## Error Handling

```lua
local ok, result = pcall(require, "optional-plugin")
if not ok then return end
local ok2, err = xpcall(risky_op, debug.traceback)  -- xpcall for stack traces
if not ok2 then vim.notify(err, vim.log.levels.ERROR) end
```

**Nested pcall:** context-prefixed names — never re-use bare `ok`/`err` in an inner scope.
```lua
local ok, err = outer_setup()
for _, server in ipairs(servers) do
  local server_ok, server_err = pcall(vim.lsp.config, server, cfg)
end
```

---

## Closures & Iterators

**Loop capture:** closures capture by reference — introduce a local to snapshot the current value.
```lua
for i = 1, 3 do local n = i; fns[i] = function() return n end end
```

`ipairs`: ordered arrays (stops at first nil). `pairs`: all keys (hash maps). `next(t)`: bypasses metamethods.

---

## Table Utilities

```lua
vim.tbl_extend("force", {}, src)                              -- shallow copy/merge
vim.tbl_deep_extend("force", defaults, overrides)             -- deep merge
vim.tbl_filter(function(x) return x > 0 end, list)
vim.tbl_map(function(x) return x * 2 end, list)
vim.tbl_contains(list, value)
table.move(src, 1, #src, #dst + 1, dst)                      -- append src into dst
local packed = table.pack(f()); f(table.unpack(packed, 1, packed.n))
```

---

## Neovim-Specific

```lua
-- Deferred UI: wrap UI calls from callbacks/timers in vim.schedule
vim.schedule(function() vim.notify("Done") end)

-- Extmarks (nvim_buf_add_highlight is deprecated)
vim.api.nvim_buf_set_extmark(buf, ns, row, col, { end_col = end_col, hl_group = "MyHL" })

-- vim.fn returns integers, not booleans — always normalise with == 1
local function is_debugpy_installed() return vim.fn.filereadable(path) == 1 end
```

---

## Naming

| Kind              | Convention    | Example                    |
|-------------------|---------------|----------------------------|
| Local variables   | `snake_case`  | `buf_count`, `active_win`  |
| Classes / modules | `PascalCase`  | `ServiceState`, `LspSetup` |
| Constants         | `UPPER_SNAKE` | `MAX_WIDTH`                |
| Private upvalues  | `_snake_case` | `_state`, `_cache`         |

**Booleans:** prefix `is_`, `has_`, `can_`, `should_` — always. **Functions:** verb phrases only — `get_server_config`, `render_row`. **Unused params:** prefix `_` — `function(choice, _index)`.

**Shadowing:** never hide an outer local, stdlib name (`os`, `string`, `table`, …), or import alias.

**Abbreviations:** approved list only (see AGENTS.md). Spell everything else out.

---

## Review Checklist

- [ ] `.new()` constructor + `:method()` colon syntax used consistently
- [ ] Optional/heavy deps use late require inside functions
- [ ] All mutable module state in a single `_state` table
- [ ] Side effects separated from pure computation
- [ ] Plugin API calls wrapped in `pcall`
- [ ] UI-touching callbacks wrapped in `vim.schedule`
- [ ] `nvim_buf_set_extmark` used, not deprecated `nvim_buf_add_highlight`
- [ ] `vim.fn` integers normalised with `== 1` before boolean use
- [ ] No shadowed variables (outer locals, stdlib, import aliases)
- [ ] Nested `pcall` pairs use context-prefixed names, not bare `ok`/`err`
- [ ] Unused params prefixed `_`
- [ ] Verb-phrase functions, `is_`/`has_` booleans, no unapproved abbreviations
- [ ] `stylua lua/` run before commit

---

## Canonical Module Template

```lua
local M = {}
local _state = { is_active = false }
local _default_opts = { enable_inlay_hints = true }

function M.setup(opts)
  local config = vim.tbl_deep_extend("force", _default_opts, opts or {})
  _state.is_active = true
  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(ctx)
      local bufnr = ctx.buf
      local client = vim.lsp.get_client_by_id(ctx.data.client_id)
      if config.enable_inlay_hints and client and client.server_capabilities.inlayHintProvider then
        vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
      end
    end,
  })
end

return M
```
