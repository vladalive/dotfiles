-- Zoom
return {
  'nyngwang/NeoZoom.lua',
  enabled = true,
  cmd = 'NeoZoomToggle',
  keys = {
    { '<leader><leader>', '<cmd>NeoZoomToggle<CR>', desc = 'Zoom window' },
  },
  config = function()
    require('neo-zoom').setup {
      popup = { enabled = true },
      winopts = {
        offset = {
          top = 0,
          left = 0,
          width = 300,
          height = 100,
        },
        border = 'none',
      },
    }
  end,
}
