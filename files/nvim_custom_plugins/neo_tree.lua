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
    local preview_config = {
      use_float = false,
      use_snacks_image = true,
      use_image_nvim = true,
    }

    local function preview(state)
      local utils = require('neo-tree.utils')
      local _, is_neo_tree_window = utils.get_appropriate_window(state)

      if is_neo_tree_window then
        local tree_win = vim.api.nvim_get_current_win()
        local split = state.current_position == 'right' and 'leftabove vnew' or 'rightbelow vnew'

        vim.cmd(split)
        vim.bo.buftype = 'nofile'
        vim.bo.bufhidden = 'wipe'
        vim.bo.swapfile = false
        vim.api.nvim_set_current_win(tree_win)
      end

      state.config = preview_config
      state.commands.preview(state)
    end

    require('neo-tree').setup {
      window = {
        mappings = {
          ['P'] = preview,
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
