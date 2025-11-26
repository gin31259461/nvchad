local snacks = require("snacks")

local M = {}

---@type LazyKeysLspSpec[]|nil
M._keys = nil

---@alias LazyKeysOpts LazyKeysBase|{has?:string|string[], silent?:boolean, buffer:unknown, cond?:fun():boolean}
---@alias LazyKeysLspSpec LazyKeysSpec|{has?:string|string[], cond?:fun():boolean}
---@alias LazyKeysLsp LazyKeys|{has?:string|string[], cond?:fun():boolean}

---@return LazyKeysLspSpec[]
function M.get()
  if M._keys then
    return M._keys
  end
  M._keys = {
    {
      "<leader>cl",
      function()
        snacks.picker.lsp_config()
      end,
      desc = "Lsp Info",
    },
    { "gd", vim.lsp.buf.definition, desc = "Goto Definition", has = "definition" },
    { "gR", vim.lsp.buf.references, desc = "References", nowait = true },
    { "gI", vim.lsp.buf.implementation, desc = "Goto Implementation" },
    { "gy", vim.lsp.buf.type_definition, desc = "Goto Type Definition" },
    { "gD", vim.lsp.buf.declaration, desc = "Goto Declaration" },
    {
      "K",
      function()
        return vim.lsp.buf.hover({
          focus = true,
          silent = true,
          border = "single",
          max_width = select(1, NvChad.ui.get_doc_window_size()),
          max_height = select(2, NvChad.ui.get_doc_window_size()),
        })
      end,
      desc = "Hover",
    },
    {
      "gK",
      function()
        return vim.lsp.buf.signature_help({
          focus = false,
          silent = true,
          max_width = select(1, NvChad.ui.get_doc_window_size()),
          max_height = select(2, NvChad.ui.get_doc_window_size()),
          border = "single",
        })
      end,
      desc = "Signature Help",
      has = "signatureHelp",
    },
    {
      "<m-k>",
      function()
        return vim.lsp.buf.signature_help({
          focus = false,
          silent = true,
          max_width = select(1, NvChad.ui.get_doc_window_size()),
          max_height = select(2, NvChad.ui.get_doc_window_size()),
          border = "single",
        })
      end,
      mode = "i",
      desc = "Signature Help",
      has = "signatureHelp",
    },
    { "<leader>ca", vim.lsp.buf.code_action, desc = "Code Action", mode = { "n", "v" }, has = "codeAction" },
    { "<leader>cC", vim.lsp.codelens.run, desc = "Run Codelens", mode = { "n", "v" }, has = "codeLens" },
    { "<leader>cc", vim.lsp.codelens.refresh, desc = "Refresh & Display Codelens", mode = { "n" }, has = "codeLens" },
    {
      "<leader>cR",
      function()
        snacks.rename.rename_file()
      end,
      desc = "Rename File",
      mode = { "n" },
      has = { "workspace/didRenameFiles", "workspace/willRenameFiles" },
    },
    { "<leader>cr", vim.lsp.buf.rename, desc = "Rename", has = "rename" },
    { "<leader>cA", NvChad.lsp.action.source, desc = "Source Action", has = "codeAction" },
    {
      "]]",
      function()
        snacks.words.jump(vim.v.count1)
      end,
      has = "documentHighlight",
      desc = "Next Reference",
      cond = function()
        return snacks.words.is_enabled()
      end,
    },
    {
      "[[",
      function()
        snacks.words.jump(-vim.v.count1)
      end,
      has = "documentHighlight",
      desc = "Prev Reference",
      cond = function()
        return snacks.words.is_enabled()
      end,
    },
    {
      "<a-n>",
      function()
        snacks.words.jump(vim.v.count1, true)
      end,
      has = "documentHighlight",
      desc = "Next Reference",
      cond = function()
        return snacks.words.is_enabled()
      end,
    },
    {
      "<a-p>",
      function()
        snacks.words.jump(-vim.v.count1, true)
      end,
      has = "documentHighlight",
      desc = "Prev Reference",
      cond = function()
        return snacks.words.is_enabled()
      end,
    },
  }

  return M._keys
end

---@param method string|string[]
function M.has(buffer, method)
  if type(method) == "table" then
    for _, m in ipairs(method) do
      if M.has(buffer, m) then
        return true
      end
    end
    return false
  end
  method = method:find("/") and method or "textDocument/" .. method
  local clients = NvChad.lsp.get_clients({ bufnr = buffer })
  for _, client in ipairs(clients) do
    if client:supports_method(method) then
      return true
    end
  end
  return false
end

---@return LazyKeysLsp[]
function M.resolve(buffer)
  local Keys = require("lazy.core.handler.keys")
  if not Keys.resolve then
    return {}
  end
  local spec = vim.tbl_extend("force", {}, M.get())
  local opts = require("plugins.lsp.config")
  local clients = NvChad.lsp.get_clients({ bufnr = buffer })
  for _, client in ipairs(clients) do
    local maps = opts.servers[client.name] and opts.servers[client.name].keys or {}
    vim.list_extend(spec, maps)
  end
  return Keys.resolve(spec)
end

function M.on_attach(_, buffer)
  local Keys = require("lazy.core.handler.keys")
  local keymaps = M.resolve(buffer)

  for _, keys in pairs(keymaps) do
    local has = not keys.has or M.has(buffer, keys.has)
    local cond = not (keys.cond == false or ((type(keys.cond) == "function") and not keys.cond()))

    if has and cond then
      ---@type LazyKeysOpts
      local opts = Keys.opts(keys)
      opts.cond = nil
      opts.has = nil
      opts.silent = opts.silent ~= false
      opts.buffer = buffer
      vim.keymap.set(keys.mode or "n", keys.lhs, keys.rhs, {
        desc = opts.desc,
        noremap = opts.noremap,
        remap = opts.remap,
        expr = opts.remap,
        nowait = opts.nowait,
        buffer = opts.buffer,
        silent = opts.silent,
      })
    end
  end
end

return M
