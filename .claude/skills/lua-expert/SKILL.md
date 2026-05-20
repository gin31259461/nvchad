---
name: lua-expert
description: Lua expert advisor for this Neovim config. Apply OOP (colon syntax, metatables, inheritance), low coupling, and separation of concerns. Use when writing or refactoring Lua modules, reviewing code quality, or asking about Lua patterns, metatables, closures, or Neovim-specific idioms.
argument-hint: [file-or-topic]
allowed-tools: [Read, Edit, Write, Bash, Glob, Grep]
---

# Lua Expert

Read referenced files in full before acting. Naming and abbreviation rules live
in AGENTS.md — enforce them.

## OOP

```lua
-- Module
local M = {}
function M.pure_fn() ... end      -- dot: no self
return M

-- Class
local MyClass = {}
MyClass.__index = MyClass
function MyClass.new(opts)         -- dot: constructor
  return setmetatable({ value = opts.value or 0 }, MyClass)
end
function MyClass:increment(by)     -- colon: self
  self.value = self.value + (by or 1)
end

-- Inheritance
local Child = setmetatable({}, { __index = Parent })
Child.__index = Child
function Child.new(opts)
  return setmetatable(Parent.new(opts), Child)
end
```

Rule: `.` for constructors/pure functions; `:` for anything operating on `self`.

## Low Coupling

- Inject deps as arguments; don't `require` inside functions.
- Wrap optional/heavy deps with `pcall(require, ...)` inside the function that
  needs them.
- All mutable module state in one table: `local _state = { ... }`.

## Separation of Concerns

Split when a file exceeds ~200 lines or mixes state/logic/UI.

| Layer  | Responsibility                   |
| ------ | -------------------------------- |
| Config | Static values, thresholds        |
| State  | `_state` — runtime mutable data  |
| Logic  | Pure computation                 |
| UI     | Rendering, keymaps, side effects |

Aggregator pattern: `plugins/ui/init.lua` only `require`s sub-files; all logic
in sub-files.

## Error Handling

```lua
local ok, result = pcall(require, "optional")
if not ok then return end

local parse_ok, parse_err = xpcall(risky_op, debug.traceback)
if not parse_ok then vim.notify(parse_err, vim.log.levels.ERROR) end
```

Nested pcall: use context-prefixed names — never reuse bare `ok`/`err` in an
inner scope.

## Neovim-Specific

```lua
-- Wrap UI calls from callbacks/timers
vim.schedule(function() vim.notify("Done") end)

-- Extmarks (nvim_buf_add_highlight is deprecated)
vim.api.nvim_buf_set_extmark(buf, ns, row, col, { end_col = end_col, hl_group = "MyHL" })

-- vim.fn returns integers — always normalise before boolean use
local function is_installed(path) return vim.fn.filereadable(path) == 1 end
```

## Closures

Loop capture — snapshot the value to avoid closing over the loop variable:

```lua
for i = 1, 3 do local n = i; fns[i] = function() return n end end
```

## Review Checklist

- [ ] `.new()` constructor + `:method()` colon syntax used consistently
- [ ] Optional/heavy deps use late `pcall(require, ...)` inside functions
- [ ] All mutable state in a single `_state` table
- [ ] UI-touching callbacks wrapped in `vim.schedule`
- [ ] `nvim_buf_set_extmark` used, not deprecated `nvim_buf_add_highlight`
- [ ] `vim.fn` integers normalised with `== 1`
- [ ] No shadowed variables (stdlib, outer locals, import aliases)
- [ ] Nested `pcall` uses context-prefixed names
- [ ] Unused params prefixed `_`
- [ ] Verb-phrase functions, `is_`/`has_` booleans, approved abbreviations only
- [ ] `stylua lua/` run before commit

## Canonical Module

```lua
local M = {}
local _state = { is_active = false }
local _default_opts = { enable_inlay_hints = true }

function M.setup(opts)
  local config = vim.tbl_deep_extend("force", _default_opts, opts or {})
  _state.is_active = true
  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(ctx)
      local client = vim.lsp.get_client_by_id(ctx.data.client_id)
      if config.enable_inlay_hints and client and client.server_capabilities.inlayHintProvider then
        vim.lsp.inlay_hint.enable(true, { bufnr = ctx.buf })
      end
    end,
  })
end

return M
```
