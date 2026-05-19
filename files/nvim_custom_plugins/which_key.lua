return {
  'folke/which-key.nvim',
  event = 'VimEnter',
  opts = {
    spec = {
      { '<leader>c', group = 'Code' },
      { '<leader>cc', group = 'Copilot Chat' },
      { '<leader>d', group = 'Document / Diagnostics' },
      { '<leader>s', group = 'Search' },
      { '<leader>w', group = 'Workspace' },
    },
  },
  keys = {
    {
      '<leader>?',
      function()
        require('which-key').show { global = false }
      end,
      desc = 'Buffer Local Keymaps (which-key)',
    },
  },
}
