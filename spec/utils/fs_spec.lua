-- ── spec/utils/fs_spec.lua ────────────────────────────────────────────────────
---@type SpecHelpers
local H = dofile(vim.env.NVIM_SPEC_DIR .. "/helpers.lua")
local fs = require("utils.fs")

local CONFIG = vim.fn.stdpath("config") --[[@as string]]

-- ── pretty_path ────────────────────────────────────────────────────────────────

H.describe("utils.fs.pretty_path", function()
  H.it("returns empty string for an explicit empty path", function()
    H.expect(fs.pretty_path("")).to_equal("")
  end)

  H.it("returns a string for any valid path", function()
    H.expect(type(fs.pretty_path(CONFIG .. "/init.lua"))).to_equal("string")
  end)

  H.it("returns a non-empty string for an existing file", function()
    local result = fs.pretty_path(CONFIG .. "/init.lua")
    H.expect(#result > 0).to_be_truthy()
  end)

  H.it("inserts ellipsis when path parts exceed length", function()
    local long = CONFIG .. "/lua/plugins/lsp/servers/base.lua"
    local result = fs.pretty_path(long, { length = 2 })
    H.expect(result:find("…") ~= nil).to_be_truthy()
  end)

  H.it("does not insert ellipsis when parts <= length", function()
    local result = fs.pretty_path("/a/b.lua", { length = 5 })
    H.expect(result:find("…") == nil).to_be_truthy()
  end)

  H.it("result ends with the filename", function()
    -- length=2 ensures: [first_seg, "…", filename] — filename is always included
    local result = fs.pretty_path(CONFIG .. "/init.lua", { length = 2 })
    H.expect(result:match("init%.lua$") ~= nil).to_be_truthy()
  end)

  H.it("only_cwd strips the cwd prefix", function()
    -- With only_cwd=true, result should be shorter than the full path
    local full = fs.pretty_path(CONFIG .. "/init.lua", { length = 99 })
    local cwd_rel = fs.pretty_path(CONFIG .. "/init.lua", { length = 99, only_cwd = true })
    -- If CONFIG is under cwd, cwd_rel should be shorter; otherwise both equal
    H.expect(type(cwd_rel)).to_equal("string")
    H.expect(#cwd_rel <= #full).to_be_truthy()
  end)
end)

-- ── scandir ────────────────────────────────────────────────────────────────────

H.describe("utils.fs.scandir", function()
  H.it("returns empty table for nonexistent path", function()
    local result = fs.scandir("/nonexistent/path/abc_xyz_123", "all")
    H.expect(type(result)).to_equal("table")
    H.expect(#result).to_equal(0)
  end)

  H.it('mode="file" returns at least one .lua file from utils/', function()
    local result = fs.scandir(CONFIG .. "/lua/utils", "file")
    H.expect(#result > 0).to_be_truthy()
  end)

  H.it('mode="file" returns only files (all entries end in .lua in utils/)', function()
    local result = fs.scandir(CONFIG .. "/lua/utils", "file")
    for _, name in ipairs(result) do
      H.expect(name:match("%.lua$") ~= nil).to_be_truthy()
    end
  end)

  H.it('mode="directory" returns directories from lua/', function()
    local result = fs.scandir(CONFIG .. "/lua", "directory")
    H.expect(#result > 0).to_be_truthy()
  end)

  H.it('mode="all" returns >= mode="file" count', function()
    local files = fs.scandir(CONFIG .. "/lua", "file")
    local all = fs.scandir(CONFIG .. "/lua", "all")
    H.expect(#all >= #files).to_be_truthy()
  end)

  H.it("returns a table even for an empty directory", function()
    local tmp = vim.fn.tempname()
    vim.fn.mkdir(tmp, "p")
    local result = fs.scandir(tmp, "all")
    H.expect(type(result)).to_equal("table")
    vim.fn.delete(tmp, "d")
  end)

  H.it("does not include . or .. entries", function()
    local result = fs.scandir(CONFIG .. "/lua/utils", "all")
    for _, name in ipairs(result) do
      H.expect(name ~= "." and name ~= "..").to_be_truthy()
    end
  end)
end)

-- ── make_relative_path ─────────────────────────────────────────────────────────

H.describe("utils.fs.make_relative_path", function()
  H.it("always returns a string", function()
    local result = fs.make_relative_path("/some/path/file.lua", "/some/path")
    H.expect(type(result)).to_equal("string")
  end)

  H.it("returns empty string when plenary is not available (graceful degradation)", function()
    -- In headless spec mode, plenary.path is not loaded.
    local result = fs.make_relative_path("/some/path/file.lua", "/some/path")
    -- Either "" (no plenary) or a relative path string
    H.expect(result == "" or result == "file.lua").to_be_truthy()
  end)
end)

-- ── constants ──────────────────────────────────────────────────────────────────

H.describe("utils.fs — exported constants", function()
  H.it("config_path is a non-empty string", function()
    H.expect(type(fs.config_path)).to_equal("string")
    H.expect(#fs.config_path > 0).to_be_truthy()
  end)

  H.it("data_path is a non-empty string", function()
    H.expect(type(fs.data_path)).to_equal("string")
    H.expect(#fs.data_path > 0).to_be_truthy()
  end)

  H.it("config_path and data_path differ", function()
    H.expect(fs.config_path ~= fs.data_path).to_be_truthy()
  end)

  H.it("root_pattern is a non-empty list of strings", function()
    H.expect(type(fs.root_pattern)).to_equal("table")
    H.expect(#fs.root_pattern > 0).to_be_truthy()
    for _, p in ipairs(fs.root_pattern) do
      H.expect(type(p)).to_equal("string")
    end
  end)

  H.it("root_pattern contains common markers", function()
    local has = function(marker)
      for _, p in ipairs(fs.root_pattern) do
        if p == marker then
          return true
        end
      end
      return false
    end
    H.expect(has(".git")).to_be_truthy()
    H.expect(has("package.json")).to_be_truthy()
  end)

  H.it("schema_paths is a table", function()
    H.expect(type(fs.schema_paths)).to_equal("table")
  end)

  H.it("schema_paths.ms_build contains config_path prefix", function()
    H.expect(fs.schema_paths.ms_build:find(fs.config_path, 1, true) ~= nil).to_be_truthy()
  end)
end)

H.summary()
