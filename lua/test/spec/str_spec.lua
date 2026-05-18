-- ── test/spec/str_spec.lua ───────────────────────────────────────────────────
local eq = assert.are.same
local str = require("utils.str")

describe("utils.str.rstrip_slash", function()
  it("removes a single trailing slash", function()
    eq("foo", str.rstrip_slash("foo/"))
  end)

  it("removes multiple consecutive trailing slashes", function()
    eq("foo", str.rstrip_slash("foo///"))
  end)

  it("leaves non-trailing slashes untouched", function()
    eq("foo/bar", str.rstrip_slash("foo/bar"))
  end)

  it("leaves interior slashes untouched", function()
    eq("/usr/local/bin", str.rstrip_slash("/usr/local/bin/"))
  end)

  it("handles empty string", function()
    eq("", str.rstrip_slash(""))
  end)

  it("handles string with only slashes", function()
    eq("", str.rstrip_slash("///"))
  end)

  it("handles a single root slash", function()
    eq("", str.rstrip_slash("/"))
  end)

  it("is a no-op when there is no trailing slash", function()
    local s = "no/slash/here"
    eq(s, str.rstrip_slash(s))
  end)

  it("is idempotent", function()
    local s = "foo/bar/"
    eq(str.rstrip_slash(s), str.rstrip_slash(str.rstrip_slash(s)))
  end)
end)
