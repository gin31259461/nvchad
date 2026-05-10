-- ── spec/utils/os_spec.lua ────────────────────────────────────────────────────
local H = dofile(vim.env.NVIM_SPEC_DIR .. "/helpers.lua")
local os_utils = require("utils.os")

H.describe("utils.os — platform detection", function()
  H.it("is_win() returns a boolean", function()
    H.expect(type(os_utils.is_win())).to_equal("boolean")
  end)

  H.it("is_linux() returns a boolean", function()
    H.expect(type(os_utils.is_linux())).to_equal("boolean")
  end)

  H.it("is_win and is_linux are mutually exclusive", function()
    if os_utils.is_linux() then
      H.expect(os_utils.is_win()).to_equal(false)
    elseif os_utils.is_win() then
      H.expect(os_utils.is_linux()).to_equal(false)
    end
    -- one of them must be true on supported platforms
    H.expect(os_utils.is_win() or os_utils.is_linux()).to_be_truthy()
  end)
end)

H.describe("utils.os — date / time", function()
  H.it("get_current_date returns YYYY-MM-DD by default", function()
    local d = os_utils.get_current_date()
    H.expect(d).to_match("^%d%d%d%d%-%d%d%-%d%d$")
  end)

  H.it("get_current_date accepts a custom format", function()
    local year = os_utils.get_current_date("%Y")
    H.expect(tonumber(year) ~= nil).to_be_truthy()
    H.expect(tonumber(year) >= 2024).to_be_truthy()
  end)

  H.it("get_current_time returns HH:MM:SS by default", function()
    local t = os_utils.get_current_time()
    H.expect(t).to_match("^%d%d:%d%d:%d%d$")
  end)

  H.it("get_current_time accepts a custom format", function()
    local h = os_utils.get_current_time("%H")
    local n = tonumber(h)
    H.expect(n ~= nil).to_be_truthy()
    H.expect(n >= 0 and n <= 23).to_be_truthy()
  end)

  H.it("get_datetime returns YYYY-MM-DD HH:MM:SS by default", function()
    local dt = os_utils.get_datetime()
    H.expect(dt).to_match("^%d%d%d%d%-%d%d%-%d%d %d%d:%d%d:%d%d$")
  end)

  H.it("get_datetime accepts a custom format", function()
    local ts = os_utils.get_datetime("%s")
    H.expect(tonumber(ts) ~= nil).to_be_truthy()
    H.expect(tonumber(ts) > 0).to_be_truthy()
  end)

  H.it("successive calls to get_datetime are non-decreasing", function()
    local t1 = tonumber(os_utils.get_datetime("%s"))
    local t2 = tonumber(os_utils.get_datetime("%s"))
    H.expect(t2 >= t1).to_be_truthy()
  end)
end)

H.describe("utils.os — environment & system", function()
  H.it("get_env returns string or nil", function()
    local val = os_utils.get_env("HOME")
    H.expect(type(val) == "string" or val == nil).to_be_truthy()
  end)

  H.it("get_env returns nil for a nonexistent variable", function()
    local val = os_utils.get_env("_NVCHAD_NONEXISTENT_VAR_XYZ_123")
    H.expect(val).to_be_nil()
  end)

  H.it("get_hostname returns string or nil", function()
    local h = os_utils.get_hostname()
    H.expect(type(h) == "string" or h == nil).to_be_truthy()
  end)

  H.it("get_hostname is non-empty when available", function()
    local h = os_utils.get_hostname()
    if h ~= nil then
      H.expect(#h > 0).to_be_truthy()
    end
  end)

  H.it("get_username returns string or nil", function()
    local u = os_utils.get_username()
    H.expect(type(u) == "string" or u == nil).to_be_truthy()
  end)

  H.it("get_username is non-empty when available", function()
    local u = os_utils.get_username()
    if u ~= nil then
      H.expect(#u > 0).to_be_truthy()
    end
  end)
end)

H.summary()
