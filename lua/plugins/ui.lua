---@type LazySpec[]
local specs = {}

for _, mod_name in ipairs({
  "plugins.ui.nvchad",
  "plugins.ui.snacks",
  "plugins.ui.noice",
  "plugins.ui.trouble",
}) do
  vim.list_extend(specs, require(mod_name))
end

return specs
