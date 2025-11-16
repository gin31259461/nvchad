local M = {}

---@param path? string
---@param opts? {length?: integer, only_cwd?: boolean}
---@return string
M.pretty_path = function(path, opts)
  opts = opts or {}

  local length = opts.length or 3
  local full_path = path or vim.fn.expand("%:p")

  if full_path == "" then
    return ""
  end

  -- Normalize and get cwd
  full_path = vim.fs.normalize(full_path)

  if opts.only_cwd then
    local cwd = vim.fn.getcwd()
    cwd = vim.fs.normalize(cwd)

    -- remove cwd prefix
    if full_path:find(cwd, 1, true) == 1 then
      full_path = full_path:sub(#cwd + 2) -- +2 to remove slash
    end
  end

  -- local sep = package.config:sub(1, 1)
  local sep = "/"
  local parts = vim.split(full_path, "[\\/]", { plain = false })

  if #parts <= length then
    return table.concat(parts, sep)
  end

  local short_parts = { parts[1], "…" }
  vim.list_extend(short_parts, vim.list_slice(parts, #parts - length + 2, #parts))

  return table.concat(short_parts, sep)
end

M.root_pattern = {
  ".git",
  ".hg",
  ".svn",
  ".bzr",
  "package.json",
  "pyproject.toml",
  "setup.py",
  "requirements.txt",
  "Pipfile",
  "Cargo.toml",
  "go.mod",
  "composer.json",
  "Gemfile",
  "Makefile",
  "CMakeLists.txt",
  "meson.build",
  "build.gradle",
  "build.gradle.kts",
  "pom.xml",
  ".idea",
  ".vscode",
}

M.sqlfluff_pattern = {
  ".sqlfluff",
  -- "pep8.ini",
  -- "pyproject.toml",
  "setup.cfg",
  -- "tox.ini",
}

local function find_root_marker(startpath, markers)
  local Path = vim.fn.expand(startpath)
  for _, marker in ipairs(markers) do
    local found = vim.fn.finddir(marker, Path .. ";")
    if found ~= "" then
      return vim.fn.fnamemodify(found, ":p:h:h")
    end
    local found_file = vim.fn.findfile(marker, Path .. ";")
    if found_file ~= "" then
      return vim.fn.fnamemodify(found_file, ":p:h")
    end
  end
end

function M.get_root()
  local bufname = vim.api.nvim_buf_get_name(0)

  -- lsp root
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients > 0 then
    for _, client in ipairs(clients) do
      if client.config and client.config.root_dir then
        return client.config.root_dir
      end
    end
  end

  -- marker files
  if bufname ~= "" then
    local root = find_root_marker(bufname, M.root_pattern)
    if root then
      return root
    end
  end

  -- current path of current file
  if bufname ~= "" then
    return vim.fn.fnamemodify(bufname, ":p:h")
  end

  -- fallback: cwd
  return vim.loop.cwd()
end

---@param buf_name string
---@param root string
---@return string
M.make_relative_path = function(buf_name, root)
  local Path_ready, Path = pcall(require, "plenary.path")

  if Path_ready then
    return Path:new(buf_name):make_relative(root)
  end

  return ""
end

---@alias ScandirMode "file" | "directory" | "all"

---@param path string
---@param mode ScandirMode
---@return table
M.scandir = function(path, mode)
  local names = {}
  local fd = vim.loop.fs_scandir(path)
  if not fd then
    return names
  end

  while true do
    local name, t = vim.loop.fs_scandir_next(fd)
    if not name then
      break
    end
    if (mode == "all") or (t == mode) then
      table.insert(names, name)
    end
  end

  return names
end

M.config_path = vim.fn.stdpath("config")
M.data_path = vim.fn.stdpath("data")

return M
