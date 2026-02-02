vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.opt.termguicolors = true

require('Comment').setup()

require('nvim-tree').setup({
  renderer = {
    icons = {
      glyphs = {
         default = nil,
       },
    },
  },
  filters = {
    dotfiles = true,
  },
})

require('neo-zoom').setup({
  popup = { enabled = true },
  winopts = {
    offset = {
      top = 0,
      left = 0,
      width = 300,
      height = 100,
    },
    border = 'none',
  },
})

require('gitsigns').setup()

require('nvim-treesitter').setup({
  highlight = {
    enable = true,
  },
  indent = { enable = true },
  ensure_installed = {
    "bash",
    "comment",
    "css",
    "diff",
    "dot",
    "git_config",
    "git_rebase",
    "gitattributes",
    "gitcommit",
    "gitignore",
    "html",
    "javascript",
    "jq",
    "json",
    "lua",
    "markdown",
    "markdown_inline",
    "pug",
    "python",
    "regex",
    "ruby",
    "scss",
    "sql",
    "ssh_config",
    "typescript",
    "vim",
    "vue",
    "xml",
    "yaml",
  },
  auto_install = true,
})

--- require('lspconfig').ruby_ls.setup({})

--- NOTE: https://github.com/Shopify/ruby-lsp/blob/main/EDITORS.md#neovim-lsp
-- textDocument/diagnostic support until 0.10.0 is released
_timers = {}
local function setup_diagnostics(client, buffer)
  if require("vim.lsp.diagnostic")._enable then
    return
  end

  local diagnostic_handler = function()
    local params = vim.lsp.util.make_text_document_params(buffer)
    client.request("textDocument/diagnostic", { textDocument = params }, function(err, result)
      if err then
        local err_msg = string.format("diagnostics error - %s", vim.inspect(err))
        vim.lsp.log.error(err_msg)
      end
      local diagnostic_items = {}
      if result then
        diagnostic_items = result.items
      end
      vim.lsp.diagnostic.on_publish_diagnostics(
        nil,
        vim.tbl_extend("keep", params, { diagnostics = diagnostic_items }),
        { client_id = client.id }
      )
    end)
  end

  diagnostic_handler() -- to request diagnostics on buffer when first attaching

  vim.api.nvim_buf_attach(buffer, false, {
    on_lines = function()
      if _timers[buffer] then
        vim.fn.timer_stop(_timers[buffer])
      end
      _timers[buffer] = vim.fn.timer_start(200, diagnostic_handler)
    end,
    on_detach = function()
      if _timers[buffer] then
        vim.fn.timer_stop(_timers[buffer])
      end
    end,
  })
end

require("lspconfig").ruby_ls.setup({
  on_attach = function(client, buffer)
    setup_diagnostics(client, buffer)
  end,
})

-- Global mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
vim.keymap.set('n', '<space>e', vim.diagnostic.open_float)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist)
