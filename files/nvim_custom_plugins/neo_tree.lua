-- Tree
return {
  'nvim-neo-tree/neo-tree.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons',
    'MunifTanjim/nui.nvim',
  },
  config = function()
    require('neo-tree').setup {
      window = {
        mappings = {
          ['P'] = {
            'toggle_preview',
            config = {
              use_float = false,
              use_snacks_image = true,
              use_image_nvim = true,
            },
          },
        },
      },
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
