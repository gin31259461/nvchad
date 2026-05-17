-- ── spec/utils/cmp_spec.lua ───────────────────────────────────────────────────
---@type SpecHelpers
local H = dofile(vim.env.NVIM_SPEC_DIR .. "/helpers.lua")
local cmp_utils = require("utils.cmp")

-- ── snippet_replace ────────────────────────────────────────────────────────────

H.describe("utils.cmp.snippet_replace", function()
  H.it("leaves plain text unchanged", function()
    local result = cmp_utils.snippet_replace("hello world", function(p)
      return p.text
    end)
    H.expect(result).to_equal("hello world")
  end)

  H.it("replaces a single ${N:text} placeholder", function()
    local result = cmp_utils.snippet_replace("${1:name}", function(p)
      return "[" .. p.text .. "]"
    end)
    H.expect(result).to_equal("[name]")
  end)

  H.it("replaces multiple placeholders in order", function()
    local result = cmp_utils.snippet_replace("${1:a}, ${2:b}", function(p)
      return p.text:upper()
    end)
    H.expect(result).to_equal("A, B")
  end)

  H.it("passes correct n field to fn", function()
    local ns = {}
    cmp_utils.snippet_replace("${3:x} ${7:y}", function(p)
      table.insert(ns, p.n)
      return p.text
    end)
    H.expect(tostring(ns[1])).to_equal("3")
    H.expect(tostring(ns[2])).to_equal("7")
  end)

  H.it("passes correct text field to fn", function()
    local texts = {}
    cmp_utils.snippet_replace("${1:foo} ${2:bar}", function(p)
      table.insert(texts, p.text)
      return p.text
    end)
    H.expect(texts[1]).to_equal("foo")
    H.expect(texts[2]).to_equal("bar")
  end)

  H.it("does not touch $0 (end stop)", function()
    local result = cmp_utils.snippet_replace("code$0", function(p)
      return p.text
    end)
    H.expect(result).to_equal("code$0")
  end)

  H.it("handles empty placeholder text", function()
    local result = cmp_utils.snippet_replace("${1:}", function(p)
      return "EMPTY"
    end)
    -- ${1:} doesn't match the pattern ^${(%d+):(.+)}$ due to empty text
    H.expect(type(result)).to_equal("string")
  end)

  H.it("handles snippet with no placeholders", function()
    local result = cmp_utils.snippet_replace("local x = 1", function()
      return "REPLACED"
    end)
    H.expect(result).to_equal("local x = 1")
  end)
end)

-- ── snippet_fix ────────────────────────────────────────────────────────────────

H.describe("utils.cmp.snippet_fix", function()
  H.it("returns unchanged string for plain text", function()
    H.expect(cmp_utils.snippet_fix("hello")).to_equal("hello")
  end)

  H.it("preserves the placeholder number after fixing", function()
    local result = cmp_utils.snippet_fix("${1:name}")
    H.expect(result:find("${1:", 1, true) ~= nil).to_be_truthy()
  end)

  H.it("returns a string for any input", function()
    H.expect(type(cmp_utils.snippet_fix("${1:a} text ${2:b}")))
      .to_equal("string")
  end)

  H.it("handles snippet with no placeholders", function()
    H.expect(cmp_utils.snippet_fix("return nil")).to_equal("return nil")
  end)
end)

-- ── map ────────────────────────────────────────────────────────────────────────

H.describe("utils.cmp.map", function()
  H.it("returns a callable function", function()
    local fn = cmp_utils.map({ "snippet_forward" })
    H.expect(type(fn)).to_equal("function")
  end)

  H.it("calls the fallback function when no action fires", function()
    local called = false
    local fn = cmp_utils.map({}, function()
      called = true
    end)
    fn()
    H.expect(called).to_equal(true)
  end)

  H.it("does not call fallback when an action returns true", function()
    local called = false
    cmp_utils.actions._spec_true = function()
      return true
    end
    local fn = cmp_utils.map({ "_spec_true" }, function()
      called = true
    end)
    fn()
    H.expect(called).to_equal(false)
    cmp_utils.actions._spec_true = nil
  end)

  H.it("returns true when an action fires successfully", function()
    cmp_utils.actions._spec_true2 = function()
      return true
    end
    local fn = cmp_utils.map({ "_spec_true2" })
    local result = fn()
    H.expect(result).to_equal(true)
    cmp_utils.actions._spec_true2 = nil
  end)

  H.it("skips unknown action names gracefully", function()
    local fn = cmp_utils.map({ "_nonexistent_action_xyz" })
    local ok = pcall(fn)
    H.expect(ok).to_equal(true)
  end)

  H.it("tries actions in order and stops at first truthy return", function()
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
    H.expect(#order).to_equal(1)
    H.expect(order[1]).to_equal("a")
    cmp_utils.actions._spec_a = nil
    cmp_utils.actions._spec_b = nil
  end)

  H.it("accepts a string fallback and returns it", function()
    local fn = cmp_utils.map({}, "fallback_string")
    local result = fn()
    H.expect(result).to_equal("fallback_string")
  end)
end)

-- ── create_undo helper (via actions.snippet_stop) ──────────────────────────────

H.describe("utils.cmp.actions.snippet_stop", function()
  H.it("exists and is callable", function()
    H.expect(type(cmp_utils.actions.snippet_stop)).to_equal("function")
  end)

  H.it("does not error when called outside a snippet session", function()
    local ok = pcall(cmp_utils.actions.snippet_stop)
    H.expect(ok).to_equal(true)
  end)
end)

H.summary()
