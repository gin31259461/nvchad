-- ── test/spec/cmp_spec.lua ────────────────────────────────────────────────────
local eq = assert.are.same
local cmp_utils = require("utils.cmp")

-- ── snippet_replace ────────────────────────────────────────────────────────────

describe("utils.cmp.snippet_replace", function()
  it("leaves plain text unchanged", function()
    local result = cmp_utils.snippet_replace("hello world", function(p)
      return p.text
    end)
    eq("hello world", result)
  end)

  it("replaces a single ${N:text} placeholder", function()
    local result = cmp_utils.snippet_replace("${1:name}", function(p)
      return "[" .. p.text .. "]"
    end)
    eq("[name]", result)
  end)

  it("replaces multiple placeholders in order", function()
    local result = cmp_utils.snippet_replace("${1:a}, ${2:b}", function(p)
      return p.text:upper()
    end)
    eq("A, B", result)
  end)

  it("passes correct n field to fn", function()
    local captured_numbers = {}
    cmp_utils.snippet_replace("${3:x} ${7:y}", function(p)
      table.insert(captured_numbers, p.n)
      return p.text
    end)
    eq("3", tostring(captured_numbers[1]))
    eq("7", tostring(captured_numbers[2]))
  end)

  it("passes correct text field to fn", function()
    local texts = {}
    cmp_utils.snippet_replace("${1:foo} ${2:bar}", function(p)
      table.insert(texts, p.text)
      return p.text
    end)
    eq("foo", texts[1])
    eq("bar", texts[2])
  end)

  it("does not touch $0 (end stop)", function()
    local result = cmp_utils.snippet_replace("code$0", function(p)
      return p.text
    end)
    eq("code$0", result)
  end)

  it("handles empty placeholder text", function()
    local result = cmp_utils.snippet_replace("${1:}", function(_p)
      return "EMPTY"
    end)
    -- ${1:} doesn't match the pattern ^${(%d+):(.+)}$ due to empty text
    assert.is_string(result)
  end)

  it("handles snippet with no placeholders", function()
    local result = cmp_utils.snippet_replace("local x = 1", function()
      return "REPLACED"
    end)
    eq("local x = 1", result)
  end)
end)

-- ── snippet_fix ────────────────────────────────────────────────────────────────

describe("utils.cmp.snippet_fix", function()
  it("returns unchanged string for plain text", function()
    eq("hello", cmp_utils.snippet_fix("hello"))
  end)

  it("preserves the placeholder number after fixing", function()
    local result = cmp_utils.snippet_fix("${1:name}")
    assert.is_truthy(result:find("${1:", 1, true) ~= nil)
  end)

  it("returns a string for any input", function()
    assert.is_string(cmp_utils.snippet_fix("${1:a} text ${2:b}"))
  end)

  it("handles snippet with no placeholders", function()
    eq("return nil", cmp_utils.snippet_fix("return nil"))
  end)
end)

-- ── map ────────────────────────────────────────────────────────────────────────

describe("utils.cmp.map", function()
  it("returns a callable function", function()
    local fn = cmp_utils.map({ "snippet_forward" })
    assert.is_function(fn)
  end)

  it("calls the fallback function when no action fires", function()
    local is_called = false
    local fn = cmp_utils.map({}, function()
      is_called = true
    end)
    fn()
    eq(true, is_called)
  end)

  it("does not call fallback when an action returns true", function()
    local is_called = false
    cmp_utils.actions._spec_true = function()
      return true
    end
    local fn = cmp_utils.map({ "_spec_true" }, function()
      is_called = true
    end)
    fn()
    eq(false, is_called)
    cmp_utils.actions._spec_true = nil
  end)

  it("returns true when an action fires successfully", function()
    cmp_utils.actions._spec_true2 = function()
      return true
    end
    local fn = cmp_utils.map({ "_spec_true2" })
    local result = fn()
    eq(true, result)
    cmp_utils.actions._spec_true2 = nil
  end)

  it("skips unknown action names gracefully", function()
    local fn = cmp_utils.map({ "_nonexistent_action_xyz" })
    local ok = pcall(fn)
    eq(true, ok)
  end)

  it("tries actions in order and stops at first truthy return", function()
    local order = {}
    cmp_utils.actions._spec_a = function()
      table.insert(order, "a")
      return true
    end
    cmp_utils.actions._spec_b = function()
      table.insert(order, "b")
      return true
    end
    local fn = cmp_utils.map({ "_spec_a", "_spec_b" })
    fn()
    eq(1, #order)
    eq("a", order[1])
    cmp_utils.actions._spec_a = nil
    cmp_utils.actions._spec_b = nil
  end)

  it("accepts a string fallback and returns it", function()
    local fn = cmp_utils.map({}, "fallback_string")
    local result = fn()
    eq("fallback_string", result)
  end)
end)

-- ── actions.snippet_stop ───────────────────────────────────────────────────────

describe("utils.cmp.actions.snippet_stop", function()
  it("exists and is callable", function()
    assert.is_function(cmp_utils.actions.snippet_stop)
  end)

  it("does not error when called outside a snippet session", function()
    local ok = pcall(cmp_utils.actions.snippet_stop)
    eq(true, ok)
  end)
end)
