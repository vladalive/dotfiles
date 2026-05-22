-- Alternate files
return {
  'tpope/vim-projectionist',
  cmd = {
    'A',
    'AD',
    'AO',
    'AS',
    'AT',
    'AV',
  },
  keys = {
    { '<leader>a<space>', '<cmd>A<CR>', desc = 'Go to [A]lternate file' },
  },
  config = function()
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
