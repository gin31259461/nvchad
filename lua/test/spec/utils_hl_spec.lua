describe("utils.hl", function()
  local hl = require("utils.hl")

  describe("util.get_hl_name_without_syntax", function()
    it(
      "strips the %%# prefix and trailing # from a highlight group string",
      function()
        assert.equals(
          "NormalFloat",
          hl.util.get_hl_name_without_syntax("%#NormalFloat#")
        )
      end
    )

    it("handles a group with dots (statusline groups)", function()
      assert.equals(
        "@statusline.git",
        hl.util.get_hl_name_without_syntax("%#@statusline.git#")
      )
    end)

    it("returns the input unchanged when there are no markers", function()
      assert.equals("NoSyntax", hl.util.get_hl_name_without_syntax("NoSyntax"))
    end)

    it("removes all # characters", function()
      local result = hl.util.get_hl_name_without_syntax("%#MyGroup#")
      assert.is_true(result:find("#") == nil)
    end)

    it("removes the %%# prefix", function()
      local result = hl.util.get_hl_name_without_syntax("%#AnyGroup#")
      assert.is_true(result:find("%%#") == nil)
    end)
  end)

  describe("statusline highlight table", function()
    it("exposes a git key", function()
      assert.is_not_nil(hl.statusline.git)
    end)

    it("exposes a copilot key", function()
      assert.is_not_nil(hl.statusline.copilot)
    end)

    it("exposes a current_file key", function()
      assert.is_not_nil(hl.statusline.current_file)
    end)

    it("exposes a text key", function()
      assert.is_not_nil(hl.statusline.text)
    end)

    it("exposes a trouble_text key", function()
      assert.is_not_nil(hl.statusline.trouble_text)
    end)

    it("exposes an active_context key", function()
      assert.is_not_nil(hl.statusline.active_context)
    end)

    it("all values are strings", function()
      for key, val in pairs(hl.statusline) do
        assert.is_true(type(val) == "string", key .. " should be a string")
      end
    end)

    it("all values contain the %%# highlight syntax marker", function()
      for key, val in pairs(hl.statusline) do
        assert.is_true(
          val:find("%%#") ~= nil,
          key .. " should contain %%# marker"
        )
      end
    end)
  end)

  describe("setup functions", function()
    it("exposes a setup function", function()
      assert.is_true(type(hl.setup) == "function")
    end)

    it("exposes a setup_diagnostic function", function()
      assert.is_true(type(hl.setup_diagnostic) == "function")
    end)

    it("exposes a setup_dap function", function()
      assert.is_true(type(hl.setup_dap) == "function")
    end)
  end)
end)
