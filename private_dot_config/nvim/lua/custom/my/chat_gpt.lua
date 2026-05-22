-- ChatGPT
return {
  'jackMort/ChatGPT.nvim',
  event = 'VeryLazy',
  dependencies = {
    'MunifTanjim/nui.nvim',
    'nvim-lua/plenary.nvim',
    'folke/trouble.nvim',
    'nvim-telescope/telescope.nvim',
  },
  config = function()
    require('chatgpt').setup {
      api_key_cmd = 'cat ' .. vim.fn.expand '$HOME/.config/.chatgpt.key',
    }
  end,
}
