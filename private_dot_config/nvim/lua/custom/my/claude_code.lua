return {
  'greggh/claude-code.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  cmd = {
    'ClaudeCode',
    'ClaudeCodeContinue',
    'ClaudeCodeResume',
    'ClaudeCodeVerbose',
    'ClaudeCodeVersion',
  },
  keys = {
    { '<C-,>', '<cmd>ClaudeCode<CR>', desc = 'Claude Code' },
    { '<C-,>', '<C-\\><C-n><cmd>ClaudeCode<CR>', desc = 'Claude Code', mode = 't' },
    { '<leader>cC', '<cmd>ClaudeCodeContinue<CR>', desc = 'Claude Code continue' },
    { '<leader>cV', '<cmd>ClaudeCodeVerbose<CR>', desc = 'Claude Code verbose' },
  },
  config = function()
    require('claude-code').setup {}
  end,
}
