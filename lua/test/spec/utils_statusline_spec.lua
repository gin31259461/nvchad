describe("utils.statusline", function()
  local statusline = require("utils.statusline")

  describe("merge_components", function()
    it("joins two components with a single space gap by default", function()
      assert.equals(
        "a b",
        statusline.merge_components({ "a", "b" }, { gap = 1 })
      )
    end)

    it("respects a custom gap size", function()
      assert.equals(
        "x   y",
        statusline.merge_components({ "x", "y" }, { gap = 3 })
      )
    end)

    it("applies a left margin", function()
      local result = statusline.merge_components(
        { "hello" },
        { gap = 0, margin = { left = 3 } }
      )
      assert.equals("   hello", result)
    end)

    it("applies a right margin", function()
      local result = statusline.merge_components(
        { "hello" },
        { gap = 0, margin = { right = 2 } }
      )
      assert.equals("hello  ", result)
    end)

    it("applies both left and right margins together", function()
      local result = statusline.merge_components(
        { "x" },
        { gap = 0, margin = { left = 1, right = 1 } }
      )
      assert.equals(" x ", result)
    end)

    it("filters out highlight-only components (no visible text)", function()
      -- "%#Some#" strips to "", so it should be removed from the output.
      local result = statusline.merge_components(
        { "a", "%#Some#", "b" },
        { gap = 0 }
      )
      assert.equals("ab", result)
    end)

    it("returns empty string when all components are highlight-only", function()
      local result = statusline.merge_components(
        { "%#A#", "%#B#" },
        { gap = 1 }
      )
      assert.equals("", result)
    end)

    it("keeps a component that mixes highlight and text", function()
      -- "%#HL#text" strips hl → "text" which is non-empty → kept
      local result = statusline.merge_components({ "%#HL#text" }, { gap = 0 })
      assert.equals("%#HL#text", result)
    end)

    it(
      "returns a single component unchanged (no margins, gap irrelevant)",
      function()
        assert.equals(
          "only",
          statusline.merge_components({ "only" }, { gap = 1 })
        )
      end
    )
  end)

  describe("break_point", function()
    it("returns a string", function()
      assert.is_true(type(statusline.break_point()) == "string")
    end)

    it("contains the statusline break marker %%<", function()
      local bp = statusline.break_point()
      -- plain search for the literal string "%<"
      assert.is_true(
        bp:find("%%<", 1, true) ~= nil or bp:find("%<", 1, true) ~= nil
      )
    end)
  end)

  describe("pretty_symbol_path", function()
    -- A "symbol" matches the pattern %#...%*%#...%* (icon + name highlight pair).
    local function make_sym(n)
      return "%#HL" .. n .. "# %*%#Name" .. n .. "#sym" .. n .. "%*"
    end

    it("returns a string", function()
      assert.is_true(
        type(statusline.pretty_symbol_path(make_sym(1), 5)) == "string"
      )
    end)

    it("returns all symbols when count is within the length limit", function()
      local syms = make_sym(1) .. "  " .. make_sym(2)
      local result = statusline.pretty_symbol_path(syms, 5)
      assert.is_true(result:find("sym1") ~= nil)
      assert.is_true(result:find("sym2") ~= nil)
    end)

    it("inserts an ellipsis when symbol count exceeds length", function()
      local parts = {}
      for i = 1, 5 do
        table.insert(parts, make_sym(i))
      end
      local result = statusline.pretty_symbol_path(table.concat(parts, "  "), 2)
      assert.is_true(result:find("…") ~= nil)
    end)

    it("keeps the first and last symbols in a truncated result", function()
      local parts = {}
      for i = 1, 5 do
        table.insert(parts, make_sym(i))
      end
      local result = statusline.pretty_symbol_path(table.concat(parts, "  "), 2)
      assert.is_true(result:find("sym1") ~= nil)
      assert.is_true(result:find("sym5") ~= nil)
    end)

    it("returns empty string when input has no symbols", function()
      local result = statusline.pretty_symbol_path("no symbols here", 3)
      -- gmatch finds nothing → parts = {} → table.concat = ""
      assert.equals("", result)
    end)
  end)

  describe("path", function()
    it("returns a string in all cases", function()
      assert.is_true(type(statusline.path()) == "string")
    end)
  end)

  describe("lsp_symbols", function()
    it("returns a string in all cases", function()
      assert.is_true(type(statusline.lsp_symbols()) == "string")
    end)
  end)

  describe("mode", function()
    it("returns a string when state.mode is nil", function()
      -- state.mode is not set before setup(); should return ""
      local result = statusline.mode()
      assert.is_true(type(result) == "string")
    end)
  end)

  describe("is_ignore_ft", function()
    it("returns false for an unrecognised filetype", function()
      local saved = vim.bo.filetype
      vim.bo.filetype = "lua"
      local result = statusline.is_ignore_ft()
      vim.bo.filetype = saved
      assert.is_false(result)
    end)

    it("returns true for nvdash filetype", function()
      local saved = vim.bo.filetype
      vim.bo.filetype = "nvdash"
      local result = statusline.is_ignore_ft()
      vim.bo.filetype = saved
      assert.is_true(result)
    end)
  end)
end)
