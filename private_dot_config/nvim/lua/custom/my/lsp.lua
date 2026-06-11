return {
  'neovim/nvim-lspconfig',
  event = { 'BufReadPre', 'BufNewFile' },
  dependencies = {
    'williamboman/mason.nvim',
    'williamboman/mason-lspconfig.nvim',
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    { 'j-hui/fidget.nvim', opts = {} },
    {
      'folke/lazydev.nvim',
      ft = 'lua',
      opts = {},
    },
  },
  config = function()
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('dotfiles-lsp-attach', { clear = true }),
      callback = function(event)
        local map = function(keys, func, desc)
          vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
        end

        map('gd', function()
          require('telescope.builtin').lsp_definitions()
        end, '[G]oto [D]efinition')
        map('gr', function()
          require('telescope.builtin').lsp_references()
        end, '[G]oto [R]eferences')
        map('gI', function()
          require('telescope.builtin').lsp_implementations()
        end, '[G]oto [I]mplementation')
        map('<leader>D', function()
          require('telescope.builtin').lsp_type_definitions()
        end, 'Type [D]efinition')
        map('<leader>ds', function()
          require('telescope.builtin').lsp_document_symbols()
        end, '[D]ocument [S]ymbols')
        map('<leader>ws', function()
          require('telescope.builtin').lsp_dynamic_workspace_symbols()
        end, '[W]orkspace [S]ymbols')
        map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
        map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')
        map('K', vim.lsp.buf.hover, 'Hover Documentation')
        map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client.server_capabilities.documentHighlightProvider then
          vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
            buffer = event.buf,
            callback = vim.lsp.buf.document_highlight,
          })

          vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
            buffer = event.buf,
            callback = vim.lsp.buf.clear_references,
          })
        end
      end,
    })

    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())

    -- LSP servers are editor support and may be Mason-managed even when
    -- project-specific linters and formatters stay project-owned.
    local servers = {
      lua_ls = {
        settings = {
          Lua = {
            runtime = { version = 'LuaJIT' },
            workspace = {
              checkThirdParty = false,
            },
            completion = {
              callSnippet = 'Replace',
            },
          },
        },
      },

      ruby_lsp = {},
    }

    local server_names = vim.tbl_keys(servers or {})

    for server_name, server in pairs(servers) do
      server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
      vim.lsp.config(server_name, server)
    end

    require('mason').setup {
      -- Keep the launch environment authoritative. Mason tools remain available,
      -- but they should not shadow project/version-manager shims such as ruby-lsp.
      PATH = 'append',
    }

    -- Keep Mason tool installs scoped to Neovim/dotfiles maintenance.
    -- Project-specific linters and formatters should come from each project.
    require('mason-tool-installer').setup { ensure_installed = { 'stylua', 'selene' } }

    require('mason-lspconfig').setup {
      ensure_installed = server_names,
      automatic_enable = server_names,
    }
  end,
}
