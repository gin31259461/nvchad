pcall(function()
  dofile(vim.g.base46_cache .. "cmp")
end)

local cmp = require("cmp")
local defaults = require("cmp.config.default")()
local auto_select = true

-- vim.api.nvim_set_hl(0, "CmpGhostText", { link = "Comment", default = true })

-- https://github.com/hrsh7th/nvim-cmp/blob/b5311ab3ed9c846b585c0c15b7559be131ec4be9/doc/cmp.txt#L450
---@type cmp.ConfigSchema
local options = {
  window = {
    completion = {
      scrollbar = true,
      -- border = defaults.window.completion.border,
    },
    documentation = {
      scrollbar = true,
      -- border = defaults.window.documentation.border,
    },
  },

  completion = { completeopt = "menu,menuone" .. (auto_select and "" or ",noselect") },

  preselect = auto_select and cmp.PreselectMode.Item or cmp.PreselectMode.None,

  snippet = {
    expand = function(args)
      require("luasnip").lsp_expand(args.body)
    end,
  },

  mapping = {
    ["<C-p>"] = cmp.mapping.select_prev_item(),
    ["<C-n>"] = cmp.mapping.select_next_item(),
    ["<C-u>"] = cmp.mapping.scroll_docs(-4),
    ["<C-d>"] = cmp.mapping.scroll_docs(4),

    -- ["<C-Space>"] = cmp.mapping.complete(),
    -- ["<C-e>"] = cmp.mapping.close(),

    ["<C-e>"] = cmp.mapping({
      i = function()
        if cmp.visible() then
          cmp.abort()
        else
          cmp.complete()
        end
      end,
      c = function()
        if cmp.visible() then
          cmp.close()
        else
          cmp.complete()
        end
      end,
    }),

    ["<CR>"] = cmp.mapping.confirm({
      behavior = cmp.ConfirmBehavior.Insert,
      select = true,
    }),

    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif require("luasnip").expand_or_jumpable() then
        require("luasnip").expand_or_jump()
      else
        fallback()
      end
    end, { "i", "s" }),

    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif require("luasnip").jumpable(-1) then
        require("luasnip").jump(-1)
      else
        fallback()
      end
    end, { "i", "s" }),
  },

  formatting = {
    fields = { "kind", "abbr", "menu" },
    format = function(entry, item)
      local icons = NvChad.config.icons.kinds
      if icons[item.kind] then
        -- with text
        -- item.kind = icons[item.kind] .. item.kind
        item.kind = icons[item.kind]
      end

      local widths = {
        abbr = vim.g.cmp_widths and vim.g.cmp_widths.abbr or 40,
        menu = vim.g.cmp_widths and vim.g.cmp_widths.menu or 30,
      }

      for key, width in pairs(widths) do
        if item[key] and vim.fn.strdisplaywidth(item[key]) > width then
          item[key] = vim.fn.strcharpart(item[key], 0, width - 1) .. "…"
        end
      end

      return item
    end,
  },

  sources = {
    { name = "nvim_lsp" },
    { name = "luasnip" },
    { name = "path" },
    { name = "buffer" },
    {
      name = "lazydev",
      -- set group index to 0 to skip loading LuaLS completions
      group_index = 0,
    },
  },

  sorting = defaults.sorting,
}

return vim.tbl_deep_extend("force", require("nvchad.cmp"), options)
