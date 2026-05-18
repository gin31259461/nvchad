-- ── test/spec/table_spec.lua ─────────────────────────────────────────────────
local eq = assert.are.same
local tbl = require("utils.table")

describe("utils.table.unique_by_key — basic deduplication", function()
  it("removes duplicates keeping first occurrence", function()
    local list = {
      { name = "a", val = 1 },
      { name = "b", val = 2 },
      { name = "a", val = 3 },
    }
    local result = tbl.unique_by_key(list, "name")
    eq(2, #result)
    eq("a", result[1].name)
    eq(1, result[1].val)
    eq("b", result[2].name)
  end)

  it("preserves insertion order", function()
    local list = {
      { id = "b" },
      { id = "a" },
      { id = "b" },
      { id = "c" },
    }
    local result = tbl.unique_by_key(list, "id")
    eq(3, #result)
    eq("b", result[1].id)
    eq("a", result[2].id)
    eq("c", result[3].id)
  end)

  it("returns all items when none are duplicated", function()
    local list = { { k = 1 }, { k = 2 }, { k = 3 } }
    local result = tbl.unique_by_key(list, "k")
    eq(3, #result)
  end)
end)

describe("utils.table.unique_by_key — edge cases", function()
  it("handles empty list", function()
    local result = tbl.unique_by_key({}, "key")
    eq(0, #result)
  end)

  it("handles single-item list", function()
    local list = { { id = 42, extra = "x" } }
    local result = tbl.unique_by_key(list, "id")
    eq(1, #result)
    eq(42, result[1].id)
  end)

  it("skips items missing the key (nil identifier)", function()
    local list = {
      { name = "a" },
      { other = "x" }, -- no 'name' key
      { name = "b" },
    }
    local result = tbl.unique_by_key(list, "name")
    eq(2, #result)
    eq("a", result[1].name)
    eq("b", result[2].name)
  end)

  it("works with numeric key values", function()
    local list = { { id = 1 }, { id = 2 }, { id = 1 }, { id = 3 } }
    local result = tbl.unique_by_key(list, "id")
    eq(3, #result)
  end)

  it("does not mutate the original list", function()
    local list = { { k = "a" }, { k = "a" } }
    tbl.unique_by_key(list, "k")
    eq(2, #list)
  end)
end)
