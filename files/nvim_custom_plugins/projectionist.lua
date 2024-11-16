-- Alternate files
return {
  'tpope/vim-projectionist',
  config = function()
    vim.keymap.set('n', '<leader>a', ':A<CR>', { silent = true, desc = 'Go to [A]lternate file' })
    vim.g.projectionist_heuristics = {
      ['*'] = {
        ['app/*.rb'] = {
          type = 'specs',
          alternate = 'spec/{}_spec.rb',
        },
        ['spec/*_spec.rb'] = {
          type = 'specs',
          alternate = 'app/{}.rb',
        },
      },
    }
  end,
}
