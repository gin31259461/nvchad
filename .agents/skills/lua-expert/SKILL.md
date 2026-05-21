---
name: lua-expert
description: Expert on the Lua language itself — semantics, idioms, performance, and gotchas. Use when writing, reviewing, debugging, or explaining Lua code, regardless of host environment. Covers Lua 5.1/5.2/5.3/5.4 differences and LuaJIT (Neovim runs LuaJIT, which is 5.1 + select 5.2/5.3 extensions). Triggers, questions about tables, metatables, metamethods, closures, upvalues, coroutines, iterators, modules, error handling, patterns, garbage collection, weak tables, environments (_ENV / setfenv), OOP, ffi, or "why does this Lua snippet behave this way".
---

# Lua Expert

Authoritative reference for the Lua language. Scope is the language and its standard libraries, not any particular embedding.

## Versions in the wild

| Version | Notes |
|---------|-------|
| 5.1     | Reference for LuaJIT. `setfenv`/`getfenv`, `unpack`, `module`. |
| 5.2     | `_ENV` replaces environments. `goto`/labels. `bit32`. |
| 5.3     | Integer subtype, bitwise operators, `//`, `<<`, `>>`, `~`. UTF-8 lib. |
| 5.4     | `<const>`, `<close>` (to-be-closed variables), generational GC. |
| LuaJIT  | 5.1 + `goto`, `__pairs`/`__ipairs` (partial), `bit` library, FFI. No integer subtype; all numbers are doubles (or 64-bit cdata via FFI). |

Always confirm target version before recommending syntax. `5.3+` features (integer division, bitwise ops as operators) won't work in LuaJIT — use `bit.band`/`bit.bor` etc.

## Values & types

Eight types: `nil`, `boolean`, `number`, `string`, `function`, `userdata`, `thread`, `table`. `type(x)` returns the type name.

- Only `nil` and `false` are falsy. `0`, `""`, and empty tables are truthy.
- Strings are immutable, interned, and 8-bit clean (binary safe).
- Numbers are double-precision floats in 5.1/5.2/LuaJIT. In 5.3+, integer/float subtypes; `math.type(x)` distinguishes.
- Functions are first-class values with lexical scoping. All functions are closures.
- `nil` in a table removes the key. Storing `nil` and "no entry" are indistinguishable.

## Tables

The only structured type. Both array and hash in one. Length operator `#` is defined only when the array part has no holes — `#{1, nil, 3}` is **undefined** (may be 1 or 3). Use explicit counters or `table.maxn` (5.1) when holes are possible.

```lua
local t = { 10, 20, 30, name = "x" }    -- mixed array + hash
t[#t + 1] = 40                          -- idiomatic append
table.insert(t, 1, 0)                   -- O(n) shift
table.remove(t)                         -- pop tail; with index, O(n) shift
```

Iteration:
- `ipairs(t)` — sequential 1..N, stops at first `nil`. Stateless.
- `pairs(t)` — all keys in unspecified order. Uses `next(t, k)` under the hood.
- Adding new keys during `pairs` is undefined; setting existing keys to `nil` is allowed in 5.1, formally undefined in 5.2+.

Tables compare by reference. Use `__eq` metamethod for structural equality (must have same metatable in 5.1/LuaJIT; relaxed in 5.3+).

## Metatables & metamethods

`setmetatable(t, mt)` attaches behavior. `getmetatable(t)` reads it (can be hidden via `__metatable`).

| Metamethod    | Triggered by                                       |
|---------------|----------------------------------------------------|
| `__index`     | `t.k` when `k` is absent. Function or table.       |
| `__newindex`  | `t.k = v` when `k` is absent. `rawset` bypasses.   |
| `__call`      | `t(args)`                                          |
| `__tostring`  | `tostring(t)`, `print(t)`                          |
| `__eq` `__lt` `__le` | `==`, `<`, `<=`. `__le` falls back to `not (b < a)` in 5.3-. |
| `__add` `__sub` `__mul` `__div` `__mod` `__pow` `__unm` `__concat` `__len` | arithmetic, `..`, `#` |
| `__metatable` | hides/protects the metatable                       |
| `__pairs`     | overrides `pairs` (5.2+, partial in LuaJIT)        |
| `__gc`        | finalizer (5.2+ for tables; 5.1 only userdata)     |
| `__close`     | `<close>` variable scope exit (5.4)                |
| `__name`      | type name shown in errors (5.3+)                   |

`__index` chains: looking up `t.k` checks `t`, then `mt.__index` (table) or calls `mt.__index(t, k)` (function). Chains can be arbitrarily deep — and arbitrarily slow. `rawget`/`rawset` skip metamethods.

## OOP

There's no built-in class system. Common pattern:

```lua
local Animal = {}
Animal.__index = Animal

function Animal.new(name)
  return setmetatable({ name = name }, Animal)
end

function Animal:speak()           -- colon: implicit self
  return self.name .. " makes a noise"
end

-- inheritance via metatable chain
local Dog = setmetatable({}, { __index = Animal })
Dog.__index = Dog

function Dog.new(name)
  local self = Animal.new(name)
  return setmetatable(self, Dog)
end

function Dog:speak()
  return self.name .. " barks"
end
```

Method-call sugar: `obj:m(a)` ≡ `obj.m(obj, a)`. Definition sugar: `function T:m(a)` ≡ `function T.m(self, a)`.

Multiple inheritance via `__index = function(t, k) ...` searching a list of parents. Mixins by copying fields. Prototype-based via shared `__index` table.

## Functions, closures, upvalues

```lua
local function counter()
  local n = 0
  return function() n = n + 1; return n end
end
```

`n` is an **upvalue** of the inner function. Each call to `counter()` creates a fresh upvalue. Two closures created in the same activation share upvalues — useful for paired getter/setter.

`debug.getupvalue` / `debug.setupvalue` / `debug.upvaluejoin` inspect and manipulate them. Avoid in production code.

Tail calls don't grow the stack: `return f(x)` is a proper tail call. `return (f(x))` is **not** (the parens force single-value adjustment, but the spec still requires it be a plain `return funccall`). Returning then calling is the only proper tail position.

Variadic: `function f(...)` then `select("#", ...)` for count, `select(n, ...)` to drop the first `n-1`. `{...}` packs but loses trailing nils — use `table.pack` (5.2+) / `table.unpack` for round-trip.

Multiple returns are **adjusted**:
- Last in an expression list: kept.
- Anywhere else: truncated to one value.
- Parens around a call: forced to one value: `(f())`.
- Inside a table constructor or arg list as last item: kept.

```lua
local a, b = f()              -- a, b = first two returns
local t = { f(), 1 }          -- f() truncated to one; t = { first, 1 }
local t = { 1, f() }          -- f() kept; expands tail
print((f()))                  -- only first return
```

## Scoping rules

- `local x` is block-scoped to the enclosing chunk/`do…end`/loop/function body.
- Global by default: bare `x = 1` writes `_G.x` (or via `_ENV` in 5.2+).
- `_ENV` is a hidden upvalue in 5.2+ — `local _ENV = sandbox` builds a sandbox by shadowing it. 5.1 uses `setfenv`/`getfenv`.
- Loop variables (`for i = 1, 10 do`) are scoped to the body; each iteration gets a fresh binding (important for closures captured inside loops).

## Error handling

```lua
local ok, err = pcall(f, arg1, arg2)
if not ok then ... end

local ok, result = xpcall(f, function(err)
  return debug.traceback(err, 2)
end, arg)
```

- `error(msg, level)` — `level=1` (default) reports the call site of `error`; `level=2` blames the caller; `level=0` adds no position info.
- Errors can be any value, not just strings. Common: `error({code=…, msg=…})`.
- `assert(v, msg)` raises `msg` (or `v` itself if `msg` nil) when `v` is falsy.
- `pcall`/`xpcall` catch errors but **do not** catch yields from coroutines. `coroutine.resume` returns `(false, err)` on error.

5.4 adds `<close>` variables for deterministic cleanup:
```lua
local f <close> = io.open("x") -- f:close() called on scope exit, even on error
```

## Coroutines

Asymmetric, stackful. Not OS threads — cooperatively scheduled.

```lua
local co = coroutine.create(function(a)
  local b = coroutine.yield(a + 1)
  return b * 2
end)
local ok, v1 = coroutine.resume(co, 10)   -- ok=true, v1=11
local ok, v2 = coroutine.resume(co, 5)    -- ok=true, v2=10
coroutine.status(co)                       -- "dead"
```

States: `suspended`, `running`, `normal` (resumed another), `dead`.

`coroutine.wrap(f)` returns a function that resumes and **re-raises** errors instead of returning `(false, err)`.

Coroutines are the backbone of async patterns — Lua has no built-in event loop, but libraries (e.g. `copas`, `lua-llthreads2`, plenary in Neovim) layer scheduling on top.

## Iterators

The generic `for` calls `iter(state, control)` repeatedly:

```lua
for k, v in pairs(t) do ... end
-- equivalent to:
local iter, state, ctrl = pairs(t)
while true do
  local k, v = iter(state, ctrl)
  if k == nil then break end
  ctrl = k
  -- body
end
```

Stateless iterator: pure function of `(state, control)`. Reentrant, cheap. `ipairs` is stateless.

Stateful iterator: closure capturing its own state. Simpler to write, can't be restarted.

```lua
local function range(n)
  local i = 0
  return function()
    i = i + 1
    if i <= n then return i end
  end
end
```

## String library & patterns

Lua patterns are **not regex** — no alternation, no backreferences (except in replacements), no `{n,m}` quantifiers.

| Class | Matches            |
|-------|--------------------|
| `%a`  | letter             |
| `%d`  | digit              |
| `%s`  | whitespace         |
| `%w`  | alphanumeric       |
| `%p`  | punctuation        |
| `%l` `%u` | lower / upper  |
| `%c`  | control char       |
| `%x`  | hex digit          |
| `.`   | any char           |
| `[…]` | set; `[^…]` negated |

Quantifiers: `*` (0+), `+` (1+), `-` (0+ lazy), `?` (0/1). Anchors: `^` start, `$` end.

Captures: `()` position capture (returns offset), `(…)` value capture. Up to 32 captures. Use `%1`-`%9` in `gsub` replacement.

`%b()` matches balanced pairs. `%f[set]` is a frontier pattern (5.1+).

```lua
string.find(s, pat, init, plain)     -- plain=true disables patterns
string.match(s, pat)                  -- returns captures (or whole match)
string.gmatch(s, pat)                 -- iterator over matches
string.gsub(s, pat, repl, n)          -- repl: string/table/function
string.format("%.2f %s", 1.5, "x")   -- printf-style
string.rep(s, n, sep)                -- 5.2+ adds sep
string.byte(s, i)                    -- code point at i
string.char(...)                     -- inverse
```

For real regex, use LPeg (Parsing Expression Grammars).

## Modules

```lua
-- mymod.lua
local M = {}
function M.greet(name) return "hi " .. name end
return M

-- caller
local mymod = require("mymod")
```

`require` caches in `package.loaded`. Second `require` returns the cached value. `package.loaded["mymod"] = nil` then re-`require` to force reload.

`package.path` (Lua sources) and `package.cpath` (C modules) use `?` substitution. `?` becomes the module name with `.` replaced by `/`.

The deprecated `module(...)` function (5.1) sets up the module's environment — avoid in new code; return a table instead.

## Garbage collection

Mark-and-sweep, incremental (5.1+) or generational (5.4 opt-in via `collectgarbage("generational")`).

- `collectgarbage("collect")` — full cycle.
- `collectgarbage("count")` — KB used.
- `collectgarbage("stop"/"restart")` — pause/resume.
- `collectgarbage("setpause", n)` / `("setstepmul", n)` — tuning.

**Weak tables** (`__mode`):
- `"k"` — weak keys (entries die when key has no other ref)
- `"v"` — weak values
- `"kv"` — both

```lua
local cache = setmetatable({}, { __mode = "v" })
```

Finalizers run via `__gc` metamethod. In 5.1, only on userdata. In 5.2+, on tables too — but the metatable must already have `__gc` set when `setmetatable` is called.

Cycles are collected normally (it's a mark-and-sweep, not refcount). Don't write reference-counting workarounds.

## Numbers (5.3+ specifics)

In 5.3+:
- `3 / 2` → `1.5` (always float)
- `3 // 2` → `1` (floor division, integer if both operands integer)
- `3 % 2` → `1`; result has sign of divisor
- `3 ^ 2` → `9.0` (always float)
- Bitwise: `&`, `|`, `~`, `<<`, `>>`, unary `~`. Operands coerced to integers.

`math.tointeger(x)` returns integer or nil. `math.type(x)` returns `"integer"`, `"float"`, or nil.

In 5.1/LuaJIT, all numbers are doubles. Bit ops via `bit` (LuaJIT) or `bit32` (5.2) library.

## LuaJIT specifics

- 100% Lua 5.1 ABI plus selected 5.2/5.3 extensions (`goto`, `__pairs`, integer division `//` in 2.1+).
- JIT compiles hot traces. Watch out for **NYI** (not yet implemented) operations — `pairs` (in 2.0; ok in 2.1), `pcall` inside JIT-compiled code (handled in 2.1), some string ops, `string.dump`. Use `jit.dump`/`-jv` to diagnose.
- `bit` library: `bit.band`, `bit.bor`, `bit.bxor`, `bit.bnot`, `bit.lshift`, `bit.rshift`, `bit.arshift`, `bit.rol`, `bit.ror`, `bit.bswap`, `bit.tobit`, `bit.tohex`.
- FFI:
  ```lua
  local ffi = require("ffi")
  ffi.cdef[[ int printf(const char *fmt, ...); ]]
  ffi.C.printf("hi\n")
  ```
  Powerful but unsafe — type mismatches and out-of-bounds access crash the process.
- `table.new(narr, nrec)` (after `require("table.new")`) pre-sizes a table.
- `table.clear(t)` empties without reallocating.
- `table.move` available without `require`.
- String interning + identity comparison makes string keys very fast.

## Performance tips (general)

- Localize globals used in hot loops: `local sin = math.sin`. One upvalue lookup vs hash hit per call.
- Concatenation: `..` is O(n). Use `table.concat(t, sep)` to join many strings.
- Avoid creating tables in hot paths; reuse and `table.clear` (LuaJIT) or zero out keys.
- `select("#", ...)` and `{...}` are cheap but not free — avoid in micro-benchmarked code.
- Method calls are slightly slower than function calls (one extra hash lookup); cache `local m = obj.method; m(obj, …)` only when it actually matters.
- Don't `pcall` in tight loops if you can hoist the check.
- For LuaJIT: keep loops type-stable. Mixing integer and float arithmetic, or returning different types from the same function, can cause traces to abort.

## Common pitfalls

1. `#` on a sparse array returns an arbitrary boundary.
2. `nil` in `{a, nil, c}` — length and `ipairs` stop at the gap.
3. Forgetting `__index = self` on a class table — methods invisible to instances.
4. `setmetatable(t, mt)` returns `t`, but chaining `setmetatable({}, mt):method()` only works if `method` is defined.
5. `local t = t` shadows correctly, but inside a method `local self = self` is redundant.
6. `string.find("foo.bar", ".")` returns 1, not 4 — `.` is a pattern. Pass `plain=true` or escape.
7. `tostring(0/0)` is `"nan"` or `"-nan"` depending on platform; `0/0 ~= 0/0`.
8. `math.random()` without `math.randomseed` is deterministic.
9. `io.lines("file")` doesn't close on early break (5.1); use `for l in io.lines(...) do` which closes on the iterator finishing, or open explicitly.
10. `require` caches by name string — `require("foo")` and `require("Foo")` are different entries even on case-insensitive filesystems.
11. Numeric `for` evaluates limit and step **once** at loop entry. Mutating the variable inside doesn't propagate.
12. Closing over loop variables: each iteration gets a fresh binding, so closures capture distinct values (unlike older JS `var`).
