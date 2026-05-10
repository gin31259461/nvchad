-- ── spec/utils/table_spec.lua ─────────────────────────────────────────────────
local H = dofile(vim.env.NVIM_SPEC_DIR .. "/helpers.lua")
local tbl = require("utils.table")

H.describe("utils.table.unique_by_key — basic deduplication", function()
  H.it("removes duplicates keeping first occurrence", function()
    local list = {
      { name = "a", val = 1 },
      { name = "b", val = 2 },
      { name = "a", val = 3 },
    }
    local result = tbl.unique_by_key(list, "name")
    H.expect(#result).to_equal(2)
    H.expect(result[1].name).to_equal("a")
    H.expect(result[1].val).to_equal(1)
    H.expect(result[2].name).to_equal("b")
  end)

  H.it("preserves insertion order", function()
    local list = {
      { id = "b" },
      { id = "a" },
      { id = "b" },
      { id = "c" },
    }
    local result = tbl.unique_by_key(list, "id")
    H.expect(#result).to_equal(3)
    H.expect(result[1].id).to_equal("b")
    H.expect(result[2].id).to_equal("a")
    H.expect(result[3].id).to_equal("c")
  end)

  H.it("returns all items when none are duplicated", function()
    local list = { { k = 1 }, { k = 2 }, { k = 3 } }
    local result = tbl.unique_by_key(list, "k")
    H.expect(#result).to_equal(3)
  end)
end)

H.describe("utils.table.unique_by_key — edge cases", function()
  H.it("handles empty list", function()
    local result = tbl.unique_by_key({}, "key")
    H.expect(#result).to_equal(0)
  end)

  H.it("handles single-item list", function()
    local list = { { id = 42, extra = "x" } }
    local result = tbl.unique_by_key(list, "id")
    H.expect(#result).to_equal(1)
    H.expect(result[1].id).to_equal(42)
  end)

  H.it("skips items missing the key (nil identifier)", function()
    local list = {
      { name = "a" },
      { other = "x" }, -- no 'name' key
      { name = "b" },
    }
    local result = tbl.unique_by_key(list, "name")
    H.expect(#result).to_equal(2)
    H.expect(result[1].name).to_equal("a")
    H.expect(result[2].name).to_equal("b")
  end)

  H.it("works with numeric key values", function()
    local list = { { id = 1 }, { id = 2 }, { id = 1 }, { id = 3 } }
    local result = tbl.unique_by_key(list, "id")
    H.expect(#result).to_equal(3)
  end)

  H.it("does not mutate the original list", function()
    local list = { { k = "a" }, { k = "a" } }
    tbl.unique_by_key(list, "k")
    H.expect(#list).to_equal(2)
  end)
end)

H.summary()
