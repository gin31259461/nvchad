local options = {
  linters_by_ft = {
    sql = { "sqlfluff" },
    python = { "ruff" },
    docker = { "hadolint" },
  },
}

return options
