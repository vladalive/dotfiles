-- Codeium
return {
  'Exafunction/codeium.nvim',
  enabled = false,
  event = 'BufEnter',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'hrsh7th/nvim-cmp',
  },
  config = function()
    require('codeium').setup {
      tools = {
        -- $ install-release get -t 'language-server-v1.8.25' https://github.com/Exafunction/codeium
        language_server = vim.fn.expand '$HOME' ..'/bin/codeium'
      },
    }
  end
}
