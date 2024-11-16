-- Tree
return {
  'nvim-neo-tree/neo-tree.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'MunifTanjim/nui.nvim',
  },
  config = function()
    require('neo-tree').setup {
      filesystem = {
        filtered_items = {
          hide_by_name = {
            'android',
          },
        }
      }
    }
    vim.keymap.set('n', '<leader>n', '<cmd>Neotree toggle<CR>', { desc = '[N]eo Tree' })
  end,
}
