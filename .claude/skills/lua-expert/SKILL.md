---
name: lua-expert
description: Lua expert advisor for this Neovim config. Apply OOP (colon syntax, metatables, inheritance), low coupling, separation of concerns, and other idiomatic Lua patterns. Use when writing or refactoring Lua modules, designing class hierarchies, splitting large files, reviewing code quality, asking "how should I structure X in Lua", or any question touching Lua patterns, metatables, closures, iterators, error handling, or Neovim-specific Lua idioms.
argument-hint: [file-or-topic]
allowed-tools: [Read, Edit, Write, Bash, Glob, Grep]
---

# Lua Expert

You are an expert developer highly proficient in the Neovim and Lua ecosystem. Your task is to
assist developers in writing, refactoring, and reviewing Neovim plugins or configuration files,
ensuring the code strictly adheres to community idioms and best practices.

Apply idiomatic Lua with a focus on OOP, low coupling, and separation of concerns.
Read referenced files before acting. When given a file, read it in full first.

---

## Core Principles

1. **Reject invalid abbreviations.** Avoid inventing abbreviations (e.g., abbreviating `category`
   to `cat`) to prevent semantic ambiguity. Clarity always supersedes brevity.
2. **Keep technical terms in their original English.** When a technical term first appears in a
   response, explain its meaning and the rationale behind its naming.
3. **Prioritise complete, intention-revealing names over short ones** — the goal is that code reads
   like prose without needing explanatory comments.

---

## 1. OOP — Module Pattern & Colon Syntax

### Simple module (no instances needed)

```lua
local M = {}

function M.greet(name)     -- dot: no implicit self, pure function
  return "Hello, " .. name
end

return M
```

### Class pattern (instances needed)

```lua
local MyClass = {}
MyClass.__index = MyClass  -- instances delegate to class for method lookup

-- Constructor: always dot syntax; returns a fresh instance table
function MyClass.new(opts)
  local self = setmetatable({}, MyClass)
  self.value = opts.value or 0
  return self
end

-- Methods: always colon syntax; receives instance as implicit `self`
function MyClass:increment(by)
  self.value = self.value + (by or 1)
end

function MyClass:__tostring()   -- metamethod via colon
  return "MyClass(" .. self.value .. ")"
end

return MyClass
```

**Rule:** use `.` for constructors and pure functions; use `:` for anything operating on `self`.
Never mix them — `obj.method(obj, ...)` is the long form of `obj:method(...)` and only one
should appear in the codebase.

### Inheritance

```lua
local Base = {}
Base.__index = Base

function Base.new(opts)
  return setmetatable({ x = opts.x }, Base)
end
function Base:area() return 0 end

-- Child
local Rect = setmetatable({}, { __index = Base })  -- Rect inherits Base
Rect.__index = Rect

function Rect.new(opts)
  local self = Base.new(opts)          -- reuse parent construction
  self.w, self.h = opts.w, opts.h
  return setmetatable(self, Rect)      -- re-stamp with child class
end

function Rect:area()                   -- override
  return self.w * self.h
end
```

---

## 2. Low Coupling

### Dependency injection over hard require

```lua
-- BAD: tight coupling, untestable, circular-risk
local function render()
  local state = require("utils.service_state").get()  -- reaches out implicitly
end

-- GOOD: accept dependencies as arguments
local function render(state, services)
  -- state and services are provided by the caller
end
```

### Late require (avoid top-level require for optional/heavy deps)

```lua
-- BAD: evaluated at module load, even if never used
local dap = require("dap")

-- GOOD: evaluate on demand
local function get_adapters()
  local ok, dap = pcall(require, "dap")
  if not ok then return {} end
  return dap.adapters
end
```

### Avoid module-level mutable state where possible

If state is needed, isolate it in a single table so callers never touch raw globals:

```lua
local state = { active = false, items = {} }   -- single source of truth
local function is_active() return state.active end
local function set_active(v) state.active = v end
```

### Observer / callback decoupling

Instead of one module calling another directly, let callers register handlers:

```lua
local M = {}
local handlers = {}

function M.on(event, fn) handlers[event] = fn end

local function emit(event, ...)
  if handlers[event] then handlers[event](...) end
end
```

### Avoid circular requires

If A requires B and B requires A, extract the shared contract into a third module C.
Alternatively, move the require inside the function that needs it (late require).

---

## 3. Separation of Concerns (SoC)

### When a module is "too large"

Split when a file has multiple distinct responsibilities. Signs:
- More than ~200 lines with unrelated sections
- Functions that could belong to two different mental categories
- State mixed with rendering mixed with actions

### The aggregator pattern (used throughout this config)

```
plugins/ui/
├── init.lua         -- aggregator: only requires submodules, zero logic
├── snacks.lua       -- snacks plugin spec + config
├── noice.lua        -- noice plugin spec + config
└── header.lua       -- data only: ASCII art strings
```

`init.lua` contains only:
```lua
return {
  require("plugins.ui.snacks"),
  require("plugins.ui.noice"),
  -- ...
}
```

### Config / State / Logic / UI separation

| Layer      | Responsibility                        | Example in this config             |
|------------|---------------------------------------|------------------------------------|
| Config     | Static values, thresholds, labels     | `cfg = { max_w = 120, ... }`       |
| State      | Runtime mutable data                  | `utils.service_state`              |
| Logic      | Pure computations, transformations    | `build_ft_groups()`, `trunc()`     |
| UI/Effects | Rendering, side effects, keymaps      | `render()`, `set_keymaps()`        |

Never let UI functions compute business logic inline; extract to named helpers.

---

## 4. Metatables & Metamethods

Key metamethods and when to use them:

| Metamethod   | Triggered by              | Common use                          |
|--------------|---------------------------|-------------------------------------|
| `__index`    | `t[k]` miss               | Inheritance, computed properties    |
| `__newindex` | `t[k] = v` (new key)      | Read-only tables, proxy/validation  |
| `__call`     | `t(...)`                  | Callable objects, factories         |
| `__tostring` | `tostring(t)`             | Debug/print representations         |
| `__len`      | `#t`                      | Custom length for non-array tables  |
| `__eq`       | `t1 == t2`                | Value equality                      |
| `__lt`/`__le`| `<`, `<=`                 | Sortable objects                    |
| `__concat`   | `t .. v`                  | String-like objects                 |

Read-only table example:
```lua
local frozen = setmetatable({}, {
  __newindex = function(_, k) error("read-only: cannot set " .. k) end,
  __index    = { foo = 1, bar = 2 },
})
```

`__index` as a function (computed properties):
```lua
local proxy = setmetatable({}, {
  __index = function(t, k)
    local val = expensive_lookup(k)
    rawset(t, k, val)   -- cache for next time
    return val
  end,
})
```

---

## 5. Error Handling

### Always use pcall at plugin/API boundaries

```lua
local ok, result = pcall(require, "some-optional-plugin")
if not ok then return end

local ok2, err = pcall(function()
  return risky_operation()
end)
if not ok2 then
  vim.notify("Error: " .. err, vim.log.levels.ERROR)
end
```

### xpcall for stack traces

```lua
local ok, err = xpcall(risky, debug.traceback)
if not ok then vim.notify(err, vim.log.levels.ERROR) end
```

### error() levels

```lua
-- level 1 (default): points at the error() call itself
-- level 2: points at the caller of the function that errored
local function expect_string(v)
  if type(v) ~= "string" then
    error("expected string, got " .. type(v), 2)
  end
end
```

---

## 6. Closures & Upvalues

Closures capture variables by reference, not by value:

```lua
-- BAD: all closures share the same `i` variable (loop variable captured by ref)
local fns = {}
for i = 1, 3 do
  fns[i] = function() return i end   -- all return 4 after loop ends
end

-- GOOD: introduce a local to capture the current value
for i = 1, 3 do
  local n = i
  fns[i] = function() return n end   -- each captures its own `n`
end
```

Use closures for private state (partial application, memoization):

```lua
local function make_counter(start)
  local n = start or 0
  return {
    inc  = function() n = n + 1 end,
    get  = function() return n end,
  }
end
```

---

## 7. Iterators

### Stateless iterator (preferred; no closure allocation per call)

```lua
local function values(t, i)
  i = i + 1
  local v = t[i]
  if v ~= nil then return i, v end
end

for i, v in values, { "a", "b", "c" }, 0 do
  print(i, v)
end
```

### Stateful iterator (closure-based)

```lua
local function filter(t, pred)
  local i = 0
  return function()
    repeat
      i = i + 1
    until t[i] == nil or pred(t[i])
    return t[i]
  end
end

for v in filter(list, function(x) return x > 0 end) do
  print(v)
end
```

### `ipairs` vs `pairs`

- `ipairs`: integer keys 1..n, stops at first nil — use for ordered arrays
- `pairs`: all keys in arbitrary order — use for hash maps
- `next(t)`: raw iteration, avoids metamethods

---

## 8. Multiple Returns & Varargs

```lua
-- Multiple returns: prefer over out-parameters or error tables
local function find(t, pred)
  for i, v in ipairs(t) do
    if pred(v) then return i, v end
  end
  return nil, "not found"
end

local idx, val = find(items, function(x) return x.id == target end)
if not idx then error(val) end  -- val is the error message here

-- Varargs: use table.pack to get count
local function sum(...)
  local args = table.pack(...)   -- args.n = actual arg count
  local total = 0
  for i = 1, args.n do total = total + (args[i] or 0) end
  return total
end
```

Forwarding varargs into a table:
```lua
local function wrap(fn, ...)
  local args = { ... }
  return function() return fn(table.unpack(args)) end
end
```

---

## 9. Table Utilities

```lua
-- Shallow copy
local copy = vim.tbl_extend("force", {}, original)

-- Deep merge (later wins on conflict)
local merged = vim.tbl_deep_extend("force", defaults, overrides)

-- Filter (no built-in; write it)
local evens = vim.tbl_filter(function(x) return x % 2 == 0 end, list)

-- Map (no built-in; write it)
local doubled = vim.tbl_map(function(x) return x * 2 end, list)

-- Check membership
if vim.tbl_contains(list, value) then ... end

-- table.move: efficient copy within/between tables
table.move(src, 1, #src, #dst + 1, dst)  -- append src into dst

-- table.pack / table.unpack
local packed = table.pack(f())   -- capture all returns; packed.n = count
f(table.unpack(packed, 1, packed.n))
```

---

## 10. String Patterns (not regex)

Lua patterns: `.` `%a` `%d` `%w` `%s` `%p` `%u` `%l` and their uppercase negations.
Anchors: `^` start, `$` end. Quantifiers: `*` `+` `?` `-` (lazy).
Captures: `()` or `(%b())` for balanced.

```lua
-- Extract captures
local year, month, day = ("2024-12-31"):match("(%d+)-(%d+)-(%d+)")

-- Global find with position
for start, stop, cap in ("foo bar baz"):gmatch("()(%a+)()") do
  print(cap, start, stop)
end

-- Replace with function
local result = s:gsub("(%a+)", function(w)
  return w:upper()
end)

-- Escape special pattern chars in user input
local escaped = user_input:gsub("[%(%)%.%%%+%-%*%?%[%^%$]", "%%%1")
```

---

## 11. Neovim-Specific Lua Patterns

### vim.schedule for deferred/safe execution

```lua
-- Always use vim.schedule when touching the UI from a callback/timer/async
pkg:install():once("closed", function()
  vim.schedule(function()
    vim.notify("Done")   -- safe: now on the main loop
    render()
  end)
end)
```

### Augroup lifecycle

```lua
local aug = vim.api.nvim_create_augroup("MyGroup", { clear = true })

vim.api.nvim_create_autocmd("BufWritePost", {
  group = aug,
  pattern = "*.lua",
  callback = function(ev) ... end,
})

-- Cleanup
pcall(vim.api.nvim_del_augroup_by_id, aug)
```

### Extmarks instead of deprecated buf_add_highlight

```lua
-- NEVER: vim.api.nvim_buf_add_highlight (deprecated)
-- ALWAYS:
vim.api.nvim_buf_set_extmark(buf, ns, row, start_col, {
  end_col  = end_col,    -- use #line for end-of-line (byte length)
  hl_group = "MyGroup",
})
```

### Safe option access

```lua
vim.bo[buf].modifiable = true    -- buffer-local
vim.wo[win].cursorline = true    -- window-local
vim.o.columns                    -- global
```

---

## 12. Self-Documenting Variable Naming

Names should reveal intent so that the code reads like prose. Never add a comment to explain
what a name means — rename it instead.

### Case conventions

| Kind                   | Convention       | Rationale                                                              | Example                          |
|------------------------|------------------|------------------------------------------------------------------------|----------------------------------|
| Local variables        | `snake_case`     | Matches the Lua standard library and Neovim's C core API tradition     | `buf_count`, `active_win`        |
| Module tables / Classes| `PascalCase`     | Signals an object prototype that can be instantiated (OOP convention)  | `ServiceState`, `LspSetup`       |
| Constants (immutable)  | `UPPER_SNAKE`    | Inherited from C macros; visually warns that the value must not change | `MAX_WIDTH`, `DEFAULT_TIMEOUT`   |
| Private (by convention)| `_snake_case`    | Lua lacks `private`; leading underscore signals "do not call externally"| `_cache`, `_handlers`           |
| Loop indexes           | `i`, `j`, `k`   | Acceptable only for numeric loops                                      |                                  |
| Generic iteratees      | `v`, `k`         | Acceptable only inside `pairs`/`ipairs` one-liners                    |                                  |

### Booleans

Prefix with `is_`, `has_`, `can_`, or `should_` so the boolean reads as a yes/no question:

```lua
-- BAD
local active = true
local error  = false
local load   = can_load()

-- GOOD
local is_active   = true
local has_error   = false
local can_load    = check_load()
```

### Functions

Name functions as verb phrases describing what they do or return:

```lua
-- BAD: noun — unclear if it returns data or has side effects
local function server_config(name) ... end

-- GOOD: verb — clearly a builder/getter
local function get_server_config(name) ... end
local function build_ft_groups(servers) ... end
local function render_service_row(state, row) ... end
```

Predicate helpers that return booleans should start with `is_`, `has_`, etc.:

```lua
local function is_enabled(service) return service.state == "on" end
local function has_active_clients(buf) return #vim.lsp.get_clients({ bufnr = buf }) > 0 end
```

### Avoid abbreviations

Only abbreviate when the short form has strong community consensus in the Neovim ecosystem.
Approved whitelist:

| Abbreviation | Stands for     | Context                                              |
|--------------|----------------|------------------------------------------------------|
| `M`          | Module export  | The table returned at the bottom of every module     |
| `opts`       | Options        | The `setup(opts)` parameter, option bags generally   |
| `bufnr`      | Buffer Number  | Neovim's unique integer identifier for a buffer      |
| `winid`      | Window ID      | Neovim's unique integer identifier for a window      |
| `ctx`        | Context        | Async callbacks, LSP event payloads                  |
| `buf`        | Buffer         | When `bufnr` would be verbose inside a local scope   |
| `win`        | Window         | Same as above for window                             |
| `ns`         | Namespace      | `vim.api.nvim_create_namespace` result               |
| `ft`         | Filetype       | `vim.bo.filetype` values                             |
| `cmd`        | Command        | Ex command string or function                        |
| `cfg`        | Config         | Local config table, not to be exported               |
| `fn`/`cb`    | Function/Callback | Only in higher-order helpers                      |

```lua
-- Avoid everything else — spell it out
-- BAD:  svc_mgr_ui_buf, act_svcs, def_tmout, cat, proc
-- GOOD: service_manager_buf, active_services, default_timeout, category, process
```

### Distinguishing similar variables

When multiple related values exist in the same scope, make the distinction explicit in the name:

```lua
-- BAD: reader must track which "line" is which
local line   = api.nvim_buf_get_lines(buf, row, row + 1, false)[1]
local line   = line:gsub("^%s+", "")   -- shadows!

-- GOOD: each step has its own name
local raw_line      = api.nvim_buf_get_lines(buf, row, row + 1, false)[1]
local trimmed_line  = raw_line:gsub("^%s+", "")
```

### Tables as named option bags

Prefer named keys over positional arguments when a function takes more than 2 parameters,
and name the parameter `opts`:

```lua
-- BAD: positional — callers must remember the order
local function open_win(buf, width, height, relative, focusable) ... end
open_win(buf, 80, 20, "editor", false)

-- GOOD: named opts — self-documenting at the call site
local function open_win(opts)
  local buf       = opts.buf
  local width     = opts.width or 80
  local is_focused = opts.focused ~= false
end
open_win({ buf = buf, width = 80, height = 20, focused = false })
```

---

- [ ] Classes use `.new()` constructor and `:method()` colon syntax consistently
- [ ] No top-level `require` for optional/heavy/circular deps — use late require or pcall
- [ ] Module state isolated in a single table; no bare module-level variables mutated externally
- [ ] Side effects (rendering, notifications, augroups) separated from pure computation
- [ ] All plugin API calls wrapped in `pcall`
- [ ] Callbacks that touch the UI use `vim.schedule`
- [ ] `nvim_buf_set_extmark` used instead of deprecated `nvim_buf_add_highlight`
- [ ] No `<C-s>` keymaps — reserved for file save
- [ ] StyLua formatting applied: `stylua lua/`
- [ ] Variable/function names are self-documenting: verb-phrase functions, `is_`/`has_` booleans, no unexplained abbreviations, no shadowing

---

## 13. Canonical Module Template

This template demonstrates all conventions together: private constants, `setup(opts)` entry point,
`LspAttach` autocmd, idiomatic abbreviations (`bufnr`, `ctx`, `opts`), and full capability names.

```lua
local M = {}

-- Private constant: _snake_case signals "internal, do not access externally"
local _default_opts = { enable_inlay_hints = true }

-- 'setup' is the community-standard initialisation function.
-- 'opts' is the idiomatic parameter name for option bags.
function M.setup(opts)
  local config = vim.tbl_deep_extend("force", _default_opts, opts or {})

  vim.api.nvim_create_autocmd("LspAttach", {
    -- 'ctx' (Context) receives the autocmd event payload
    callback = function(ctx)
      -- 'bufnr' (Buffer Number) is the conventional abbreviation for the buffer integer id
      local bufnr = ctx.buf
      local client = vim.lsp.get_client_by_id(ctx.data.client_id)

      -- Keep capability names complete — 'inlayHintProvider' must not be shortened
      if config.enable_inlay_hints
        and client
        and client.server_capabilities.inlayHintProvider
      then
        vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
      end
    end,
  })
end

return M
```
