-- ── spec/utils/str_spec.lua ───────────────────────────────────────────────────
---@type SpecHelpers
local H = dofile(vim.env.NVIM_SPEC_DIR .. "/helpers.lua")
local str = require("utils.str")

H.describe("utils.str.rstrip_slash", function()
  H.it("removes a single trailing slash", function()
    H.expect(str.rstrip_slash("foo/")).to_equal("foo")
  end)

  H.it("removes multiple consecutive trailing slashes", function()
    H.expect(str.rstrip_slash("foo///")).to_equal("foo")
  end)

  H.it("leaves non-trailing slashes untouched", function()
    H.expect(str.rstrip_slash("foo/bar")).to_equal("foo/bar")
  end)

  H.it("leaves interior slashes untouched", function()
    H.expect(str.rstrip_slash("/usr/local/bin/")).to_equal("/usr/local/bin")
  end)

  H.it("handles empty string", function()
    H.expect(str.rstrip_slash("")).to_equal("")
  end)

  H.it("handles string with only slashes", function()
    H.expect(str.rstrip_slash("///")).to_equal("")
  end)

  H.it("handles a single root slash", function()
    H.expect(str.rstrip_slash("/")).to_equal("")
  end)

  H.it("is a no-op when there is no trailing slash", function()
    local s = "no/slash/here"
    H.expect(str.rstrip_slash(s)).to_equal(s)
  end)

  H.it("is idempotent", function()
    local s = "foo/bar/"
    H.expect(str.rstrip_slash(str.rstrip_slash(s))).to_equal(str.rstrip_slash(s))
  end)
end)

H.summary()
