describe("service.order", function()
  local order
  local state
  local services = require("config.services")

  before_each(function()
    package.loaded["service.order"] = nil
    package.loaded["service.state"] = nil
    state = require("service.state")
    order = require("service.order")
  end)

  after_each(function()
    state.get().formatter_order["_test_ft_order_"] = nil
    if services.formatter_defaults.python then
      state.set_order(
        "formatter",
        "python",
        vim.deepcopy(services.formatter_defaults.python)
      )
    end
    for _, name in ipairs({
      "ruff_fix",
      "ruff_organize_imports",
      "ruff_format",
    }) do
      if services.formatter[name] then
        state.set_enabled("formatter", name, true)
      end
    end
  end)

  it("applies saved order to an existing runtime list", function()
    state.set_order("formatter", "_test_ft_order_", { "a", "b" })

    assert.same(
      { "a", "b", "z" },
      order.names_for_ft("formatter", "_test_ft_order_", { "b", "z", "a" })
    )
  end)

  it(
    "filters disabled managed services but preserves unknown runtime entries",
    function()
      state.set_order("formatter", "python", { "ruff_fix", "ruff_format" })
      state.set_enabled("formatter", "ruff_format", false)

      assert.same(
        { "ruff_fix", "external_formatter" },
        order.enabled_names_for_ft(
          "formatter",
          "python",
          { "ruff_format", "external_formatter", "ruff_fix" }
        )
      )
    end
  )
end)
