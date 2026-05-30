---
name: lua
description: Apply idiomatic Lua language patterns and module architecture when writing or refactoring `.lua` files. Use for module layout, metatables/OOP, closures, iterators, error handling (pcall/xpcall), perf-sensitive code, LuaCATS annotations, and lazy initialization. Use whenever a task touches Lua source — not just Neovim plugin specs — so the result fits the project's module pattern and `lua/utils/` facade rather than reinventing structure.
---

# Lua

Language-level guidance for writing and refactoring Lua in this repository: how to structure a module, when to reach for metatables, how to surface a clean public API, and how to avoid the cost-by-paper-cuts perf traps that show up in hot Neovim paths. The skill assumes Lua 5.1 / LuaJIT semantics (what Neovim ships) and the module pattern documented in `AGENTS.md`.

## When to Use

- Creating a new `lua/` file or extending an existing utility module.
- Designing a public API: which functions to export, how to type them, how to namespace.
- Choosing between plain tables, closures, and metatable-based OOP for a given problem.
- Adding error handling: deciding `error` vs. `assert` vs. returning `nil, err` vs. `pcall`.
- Performance work in hot paths (statusline, autocmd handlers, completion sources).
- Reviewing a Lua change for idiom violations before `make pr-ready`.

## When Not to Use

- Plugin spec authoring for lazy.nvim (use the spec patterns in `lua/plugins/` directly).
- Mason / LSP / DAP package wiring (those are declarative entries in `lua/config/services.lua`).
- Pure configuration edits in `chadrc.lua` or `options.lua` — no architecture decision needed.
- Shell, Python, or VimL work — this skill is Lua-only.

## Inputs

| Input | Required | Description |
|-------|----------|-------------|
| Target file or module | Yes | The `lua/...` path being authored or modified |
| API shape | If new module | Functions to export, intended callers |
| Hot-path? | Recommended | Whether the code runs per-keystroke, per-render, or per-autocmd event |
| Public vs. internal | Recommended | Whether other modules will require this, or it stays file-local |

## Core Patterns

### Module pattern (default)

```lua
local M = {}

local function private_helper(x)
  return x + 1
end

---@param value number
---@return number
function M.public_fn(value)
  return private_helper(value)
end

return M
```

Rules:

- `local M = {}` at top, `return M` at bottom. No other return shapes.
- Private functions are file-locals above `M`. Do **not** prefix with `_` — locality is the access modifier.
- No side effects at `require` time. Initialization belongs in `M.setup()` or a lazy plugin `config`/`opts` block.
- One concern per file. If a module grows past ~300 lines or two responsibilities, split it.

### OOP via metatables (when state + behavior travel together)

Reach for this only when you have multiple instances each carrying state. A single global registry is a module, not a class.

```lua
---@class Foo
---@field name string
local Foo = {}
Foo.__index = Foo

---@param name string
---@return Foo
function Foo.new(name)
  return setmetatable({ name = name }, Foo)
end

function Foo:greet()
  return "hi " .. self.name
end

return Foo
```

Rules:

- Constructor is `.new` (dot), methods use `:` (colon). Do not mix.
- Set `__index = Class` once; do not re-set per instance.
- Annotate the class with `---@class` so callers get completion.
- Avoid deep inheritance chains — composition or table merging is almost always clearer.

### Closures (when you need *one* stateful thing)

```lua
local function make_counter()
  local n = 0
  return function()
    n = n + 1
    return n
  end
end
```

Prefer closures over a one-instance "class". They're cheaper and read top-to-bottom.

### Iterators

- Use `ipairs` for arrays (1..n contiguous), `pairs` for maps. Don't `pairs` an array — it's slower and order is undefined.
- For numeric ranges, `for i = 1, #t do` beats `ipairs` in tight loops.
- Custom iterators: return a stateless iterator function — `for x in iter(t) do` — over building tables when the caller might break early.

### Error handling

| Situation | Pattern |
|-----------|---------|
| Programmer error (invariant violation, bad arg from internal caller) | `assert(cond, msg)` or `error("...", 2)` |
| Expected failure (file missing, network call fails) | Return `nil, err_string` |
| Crossing an async/event boundary (autocmd, scheduled callback, RPC handler) | Wrap the body in `pcall` and log via `utils.logger`; never let an error escape to Neovim's event loop |
| Calling untrusted user config | `pcall` and surface a clean message |

Do **not** sprinkle `pcall` defensively inside internal call chains — it hides bugs and slows hot paths. `pcall` is a boundary tool.

### LuaCATS annotations

Annotate every public function and any non-obvious internal one:

```lua
---@param path string Absolute path to read.
---@param opts? { binary?: boolean }
---@return string? contents
---@return string? err
function M.read_file(path, opts) ... end
```

- Use `?` for nullable params/returns; do not invent `nil | string` strings.
- Define complex shapes as `---@class` or `---@alias` near the top of the file, not inline at every call site.
- For tables-as-records, prefer `---@class` with `---@field` lines over `table<string, any>`.

## Architecture Conventions (this repo)

### The `utils/` facade

`require("utils")` is the entry point. Sub-modules (`utils.fs`, `utils.lsp`, etc.) are accessed through the facade — it proxies `lazy.core.util` and exposes curated helpers.

When adding utilities:

- **Extend an existing sub-module** if the concern already has a home (`utils.str`, `utils.table`, `utils.ui`, ...).
- **Do not** create a new top-level `utils/<thing>.lua` for a single function. Find the closest existing module and add to it.
- **Do not** reach into `lazy.core.util` from outside `utils/init.lua`. The facade is the contract.

### Services registry

`lua/config/services.lua` is the single source of truth for LSP servers, DAP adapters, linters, formatters. `config/packages.lua` derives `lsp_servers` and `mason_ensure_installed` from it. Never hard-code a Mason package name in a plugin spec — add it to `services.lua` and let the derivation handle the rest.

### Service Manager UI

`lua/service/` modules share state through a `ui` table (buffer, window, line_map, category_idx) passed via `init()` calls. Rendering logic stays in `renderer.lua`; user actions in `actions.lua`. Adding behavior? Pick the right module — do not cross the boundary.

### Plugin specs vs. application code

`lua/plugins/*.lua` returns `LazySpec[]`. Keep specs declarative — `event`, `ft`, `cmd`, `keys`, `opts`, `config`. Real logic belongs in a `lua/` module that the spec's `config` requires. Avoid `lazy = false` unless the plugin truly cannot be event/ft/cmd loaded.

## Performance Notes

For hot paths only (statusline render, completion source, per-keystroke autocmds):

- **Localize hot globals**: `local insert = table.insert` at file top beats repeated `table.insert` lookups.
- **Avoid `string.format`** in tight loops if `..` concatenation suffices — `format` is ~3x slower.
- **Prefer numeric `for`** over `ipairs` for arrays you iterate millions of times.
- **Avoid `pairs` for ordering-dependent logic** — it has no guaranteed order in Lua 5.1.
- **Cache table lookups**: `local cfg = require("config")` once at module load, not inside every function.
- **Don't preallocate** with `table.new` — LuaJIT handles it; the dependency isn't worth it.

For everything else, write the clearest code first. Measure with `vim.loop.hrtime()` before optimizing.

## Workflow

### Step 1: Locate the right home

Before creating a new file, search for an existing module that owns the concern:

```bash
rg -l "function M\." lua/utils/
```

If a sub-module fits, extend it. If not, justify the new file in the commit message.

### Step 2: Pick the right pattern

| Question | Answer |
|----------|--------|
| Stateless functions grouped by topic? | **Module** (`local M = {}`) |
| Multiple instances with behavior? | **Metatable class** (`Foo.new`, `Foo:method`) |
| Single piece of state, one consumer? | **Closure** |
| Declarative configuration? | **Plain table**, no functions |

### Step 3: Write the public surface first

Decide what `M.x` callers will use *before* writing internals. Annotate it with LuaCATS. The internals follow the contract, not the other way around.

### Step 4: Add tests if logic is non-trivial

Tests live in `lua/test/spec/`. The harness in `lua/test/helpers.lua` provides `describe`/`it`/`expect` — no external deps. Run via `make test`.

### Step 5: Run the quality gates

```bash
make fmt    # stylua
make lint   # luacheck
make test
```

Or `make pr-ready` to run all three.

## Validation

- [ ] Module returns `M`, no other shape.
- [ ] No side effects at `require` time.
- [ ] Public functions have LuaCATS annotations.
- [ ] Private helpers are file-local (no `_` prefix as a substitute for locality).
- [ ] `pcall` is at boundaries only, not sprinkled defensively.
- [ ] No new top-level `utils/<x>.lua` for a single function.
- [ ] No hard-coded Mason package names outside `services.lua`.
- [ ] `make fmt && make lint && make test` all pass.

## Common Pitfalls

| Pitfall | Solution |
|---------|----------|
| `_M.foo` or `_private` naming | Use file-local `local function foo(...)` — locality is the access modifier |
| Setting `__index` per instance | Set it once on the class table: `Foo.__index = Foo` |
| `pcall` around every internal call | Use `pcall` only at boundaries (autocmd, RPC, user config); let internal errors propagate |
| `pairs` on an array | Use `ipairs` or numeric `for` — `pairs` is slower and unordered |
| `require` in a hot function | Hoist to module top so the require cache is hit once |
| `lazy = false` on a plugin spec | Use `event`, `ft`, `cmd`, or `keys` — almost everything is lazy-loadable |
| New `lua/utils/<x>.lua` for one helper | Extend the nearest existing sub-module |
| Mason package name in a plugin spec | Add to `lua/config/services.lua` and let `packages.lua` derive it |
| `---@param x table` for a known shape | Define a `---@class` or `---@alias` and reference it |
| Reaching into `lazy.core.util` directly | Go through `require("utils")` — it proxies what you need |

## References

- `AGENTS.md` — repo conventions and quality gates
- `lua/utils/init.lua` — facade and sub-module surface
- `lua/config/services.lua` — services registry
- [LuaCATS annotations](https://luals.github.io/wiki/annotations/)
- [Lua 5.1 reference](https://www.lua.org/manual/5.1/) (Neovim's runtime)
