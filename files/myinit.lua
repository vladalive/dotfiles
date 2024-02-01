vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.opt.termguicolors = true

require('Comment').setup()

require('nvim-tree').setup({
  filters = {
    dotfiles = true,
  },
})

require('lualine').setup()

--- require('treesitter')
