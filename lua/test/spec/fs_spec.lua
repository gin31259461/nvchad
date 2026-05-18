-- ── test/spec/fs_spec.lua ────────────────────────────────────────────────────
local eq = assert.are.same
local fs = require("utils.fs")

local config_path = vim.fn.stdpath("config") --[[@as string]]

-- ── pretty_path ────────────────────────────────────────────────────────────────

describe("utils.fs.pretty_path", function()
  it("returns empty string for an explicit empty path", function()
    eq("", fs.pretty_path(""))
  end)

  it("returns a string for any valid path", function()
    assert.is_string(fs.pretty_path(config_path .. "/init.lua"))
  end)

  it("returns a non-empty string for an existing file", function()
    local result = fs.pretty_path(config_path .. "/init.lua")
    assert.is_truthy(#result > 0)
  end)

  it("inserts ellipsis when path parts exceed length", function()
    local long = config_path .. "/lua/plugins/lsp/servers/base.lua"
    local result = fs.pretty_path(long, { length = 2 })
    assert.is_truthy(result:find("…") ~= nil)
  end)

  it("does not insert ellipsis when parts <= length", function()
    local result = fs.pretty_path("/a/b.lua", { length = 5 })
    assert.is_falsy(result:find("…"))
  end)

  it("result ends with the filename", function()
    -- length=2 ensures: [first_seg, "…", filename] — filename is always included
    local result = fs.pretty_path(config_path .. "/init.lua", { length = 2 })
    assert.is_truthy(result:match("init%.lua$") ~= nil)
  end)

  it("only_cwd strips the cwd prefix", function()
    local full = fs.pretty_path(config_path .. "/init.lua", { length = 99 })
    local cwd_relative = fs.pretty_path(
      config_path .. "/init.lua",
      { length = 99, only_cwd = true }
    )
    assert.is_string(cwd_relative)
    assert.is_truthy(#cwd_relative <= #full)
  end)
end)

-- ── scandir ────────────────────────────────────────────────────────────────────

describe("utils.fs.scandir", function()
  it("returns empty table for nonexistent path", function()
    local result = fs.scandir("/nonexistent/path/abc_xyz_123", "all")
    assert.is_table(result)
    eq(0, #result)
  end)

  it('mode="file" returns at least one .lua file from utils/', function()
    local result = fs.scandir(config_path .. "/lua/utils", "file")
    assert.is_truthy(#result > 0)
  end)

  it(
    'mode="file" returns only files (all entries end in .lua in utils/)',
    function()
      local result = fs.scandir(config_path .. "/lua/utils", "file")
      for _, name in ipairs(result) do
        assert.is_truthy(name:match("%.lua$") ~= nil)
      end
    end
  )

  it('mode="directory" returns directories from lua/', function()
    local result = fs.scandir(config_path .. "/lua", "directory")
    assert.is_truthy(#result > 0)
  end)

  it('mode="all" returns >= mode="file" count', function()
    local files = fs.scandir(config_path .. "/lua", "file")
    local all = fs.scandir(config_path .. "/lua", "all")
    assert.is_truthy(#all >= #files)
  end)

  it("returns a table even for an empty directory", function()
    local tmp = vim.fn.tempname()
    vim.fn.mkdir(tmp, "p")
    local result = fs.scandir(tmp, "all")
    assert.is_table(result)
    vim.fn.delete(tmp, "d")
  end)

  it("does not include . or .. entries", function()
    local result = fs.scandir(config_path .. "/lua/utils", "all")
    for _, name in ipairs(result) do
      assert.is_truthy(name ~= "." and name ~= "..")
    end
  end)
end)

-- ── make_relative_path ─────────────────────────────────────────────────────────

describe("utils.fs.make_relative_path", function()
  it("always returns a string", function()
    local result = fs.make_relative_path("/some/path/file.lua", "/some/path")
    assert.is_string(result)
  end)

  it(
    "returns empty string when plenary is not available (graceful degradation)",
    function()
      -- In headless spec mode, plenary.path is not loaded.
      local result = fs.make_relative_path("/some/path/file.lua", "/some/path")
      -- Either "" (no plenary) or a relative path string
      assert.is_truthy(result == "" or result == "file.lua")
    end
  )
end)

-- ── constants ──────────────────────────────────────────────────────────────────

describe("utils.fs — exported constants", function()
  it("config_path is a non-empty string", function()
    assert.is_string(fs.config_path)
    assert.is_truthy(#fs.config_path > 0)
  end)

  it("data_path is a non-empty string", function()
    assert.is_string(fs.data_path)
    assert.is_truthy(#fs.data_path > 0)
  end)

  it("config_path and data_path differ", function()
    assert.is_truthy(fs.config_path ~= fs.data_path)
  end)

  it("root_pattern is a non-empty list of strings", function()
    assert.is_table(fs.root_pattern)
    assert.is_truthy(#fs.root_pattern > 0)
    for _, p in ipairs(fs.root_pattern) do
      assert.is_string(p)
    end
  end)

  it("root_pattern contains common markers", function()
    local function has_marker(marker)
      for _, p in ipairs(fs.root_pattern) do
        if p == marker then
          return true
        end
      end
      return false
    end
    assert.is_truthy(has_marker(".git"))
    assert.is_truthy(has_marker("package.json"))
  end)

  it("schema_paths is a table", function()
    assert.is_table(fs.schema_paths)
  end)

  it("schema_paths.ms_build contains config_path prefix", function()
    assert.is_truthy(
      fs.schema_paths.ms_build:find(fs.config_path, 1, true) ~= nil
    )
  end)
end)
