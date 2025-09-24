pcall(function()
  dofile(vim.g.base46_cache .. "cmp")
end)

vim.o.pumheight = select(2, NvChad.ui.get_completion_window_size())

local cmp = require("cmp")
local defaults = require("cmp.config.default")()
local auto_select = true

-- https://github.com/hrsh7th/nvim-cmp/blob/b5311ab3ed9c846b585c0c15b7559be131ec4be9/doc/cmp.txt#L450
---@type cmp.ConfigSchema
local options = {
  window = {
    completion = {
      -- border = defaults.window.completion.border,

      scrollbar = true,
      col_offset = -1,
    },
    documentation = {
      -- border = defaults.window.documentation.border,

      scrollbar = true,
      max_width = select(1, NvChad.ui.get_doc_window_size()),
      max_height = select(2, NvChad.ui.get_doc_window_size()),
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
      local max_width = select(1, NvChad.ui.get_completion_window_size())
      if icons[item.kind] then
        -- with text
        -- item.kind = icons[item.kind] .. item.kind
        item.kind = icons[item.kind]
      end

      local widths = {
        abbr = vim.g.cmp_widths and vim.g.cmp_widths.abbr or math.floor(max_width * 4 / 7),
        menu = vim.g.cmp_widths and vim.g.cmp_widths.menu or math.floor(max_width * 3 / 7),
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
    { name = "lazydev" },
  },

  sorting = defaults.sorting,

  experimental = {
    ghost_text = {
      hl_group = "CmpGhostText",
    },
  },
}

return vim.tbl_deep_extend("force", require("nvchad.cmp"), options)
