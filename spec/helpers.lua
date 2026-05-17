-- ── spec/helpers.lua ──────────────────────────────────────────────────────────
-- Minimal describe / it / expect test framework for NvChad config specs.
--
-- Usage (in each spec file):
--   local H = dofile(vim.env.NVIM_SPEC_DIR .. "/helpers.lua")
--   H.describe("module", function()
--     H.it("does X", function() H.expect(val).to_equal(expected) end)
--   end)
--   H.summary()

---@class SpecExpect
---@field to_equal      fun(expected: any)
---@field to_be_truthy  fun()
---@field to_be_falsy   fun()
---@field to_be_nil     fun()
---@field to_match      fun(pattern: string)
---@field to_have_length fun(n: integer)
---@field to_be_type    fun(t: string)

---@class SpecHelpers
---@field describe  fun(name: string, fn: fun())
---@field it        fun(name: string, fn: fun())
---@field expect    fun(val: any): SpecExpect
---@field summary   fun()
local M = {}

local _pass = 0
local _fail = 0
local _current = "(root)"

---@param name string
---@param fn fun()
function M.describe(name, fn)
  _current = name
  print("\n" .. name)
  fn()
  _current = "(root)"
end

---@param name string
---@param fn fun()
function M.it(name, fn)
  local ok, err = pcall(fn)
  if ok then
    _pass = _pass + 1
    print("  ✓ " .. name)
  else
    _fail = _fail + 1
    print("  ✗ " .. name)
    print("    " .. tostring(err):gsub("\n", "\n    "))
  end
end

---@param val any
---@return SpecExpect
function M.expect(val)
  local function fail(msg)
    error(msg, 3)
  end

  return {
    to_equal = function(expected)
      if val ~= expected then
        fail(
          string.format(
            "expected %s, got %s",
            vim.inspect(expected),
            vim.inspect(val)
          )
        )
      end
    end,
    to_be_truthy = function()
      if not val then
        fail(string.format("expected truthy, got %s", vim.inspect(val)))
      end
    end,
    to_be_falsy = function()
      if val then
        fail(string.format("expected falsy, got %s", vim.inspect(val)))
      end
    end,
    to_be_nil = function()
      if val ~= nil then
        fail(string.format("expected nil, got %s", vim.inspect(val)))
      end
    end,
    to_match = function(pattern)
      if type(val) ~= "string" or not val:match(pattern) then
        fail(
          string.format(
            "expected %s to match pattern %q",
            vim.inspect(val),
            pattern
          )
        )
      end
    end,
    to_have_length = function(n)
      local len = type(val) == "table" and #val
        or (type(val) == "string" and #val or nil)
      if len ~= n then
        fail(string.format("expected length %d, got %s", n, vim.inspect(val)))
      end
    end,
    to_be_type = function(t)
      if type(val) ~= t then
        fail(
          string.format(
            "expected type %q, got type %q (%s)",
            t,
            type(val),
            vim.inspect(val)
          )
        )
      end
    end,
  }
end

--- Print summary and exit with code 0 (all pass) or 1 (any fail).
function M.summary()
  local total = _pass + _fail
  print(string.format("\n── %d/%d passed ──", _pass, total))
  if _fail > 0 then
    print(string.format("   %d FAILED", _fail))
    vim.cmd("cq 1")
  else
    vim.cmd("quit")
  end
end

return M
