-- ── test/spec/os_spec.lua ────────────────────────────────────────────────────
local eq = assert.are.same
local os_utils = require("utils.os")

describe("utils.os — platform detection", function()
  it("is_win() returns a boolean", function()
    assert.is_boolean(os_utils.is_win())
  end)

  it("is_linux() returns a boolean", function()
    assert.is_boolean(os_utils.is_linux())
  end)

  it("is_win and is_linux are mutually exclusive", function()
    if os_utils.is_linux() then
      eq(false, os_utils.is_win())
    elseif os_utils.is_win() then
      eq(false, os_utils.is_linux())
    end
    assert.is_truthy(os_utils.is_win() or os_utils.is_linux())
  end)
end)

describe("utils.os — date / time", function()
  it("get_current_date returns YYYY-MM-DD by default", function()
    local d = os_utils.get_current_date()
    assert.is_truthy(d:match("^%d%d%d%d%-%d%d%-%d%d$"))
  end)

  it("get_current_date accepts a custom format", function()
    local year = os_utils.get_current_date("%Y")
    assert.is_truthy(tonumber(year) ~= nil)
    assert.is_truthy(tonumber(year) >= 2024)
  end)

  it("get_current_time returns HH:MM:SS by default", function()
    local t = os_utils.get_current_time()
    assert.is_truthy(t:match("^%d%d:%d%d:%d%d$"))
  end)

  it("get_current_time accepts a custom format", function()
    local hour = os_utils.get_current_time("%H")
    local n = tonumber(hour)
    assert.is_truthy(n ~= nil)
    assert.is_truthy(n >= 0 and n <= 23)
  end)

  it("get_datetime returns YYYY-MM-DD HH:MM:SS by default", function()
    local datetime = os_utils.get_datetime()
    assert.is_truthy(datetime:match("^%d%d%d%d%-%d%d%-%d%d %d%d:%d%d:%d%d$"))
  end)

  it("get_datetime accepts a custom format", function()
    local timestamp = os_utils.get_datetime("%s")
    assert.is_truthy(tonumber(timestamp) ~= nil)
    assert.is_truthy(tonumber(timestamp) > 0)
  end)

  it("successive calls to get_datetime are non-decreasing", function()
    local t1 = tonumber(os_utils.get_datetime("%s"))
    local t2 = tonumber(os_utils.get_datetime("%s"))
    assert.is_truthy(t2 >= t1)
  end)
end)

describe("utils.os — environment & system", function()
  it("get_env returns string or nil", function()
    local val = os_utils.get_env("HOME")
    assert.is_truthy(type(val) == "string" or val == nil)
  end)

  it("get_env returns nil for a nonexistent variable", function()
    local val = os_utils.get_env("_NVCHAD_NONEXISTENT_VAR_XYZ_123")
    assert.is_nil(val)
  end)

  it("get_hostname returns string or nil", function()
    local hostname = os_utils.get_hostname()
    assert.is_truthy(type(hostname) == "string" or hostname == nil)
  end)

  it("get_hostname is non-empty when available", function()
    local hostname = os_utils.get_hostname()
    if hostname ~= nil then
      assert.is_truthy(#hostname > 0)
    end
  end)

  it("get_username returns string or nil", function()
    local username = os_utils.get_username()
    assert.is_truthy(type(username) == "string" or username == nil)
  end)

  it("get_username is non-empty when available", function()
    local username = os_utils.get_username()
    if username ~= nil then
      assert.is_truthy(#username > 0)
    end
  end)
end)
