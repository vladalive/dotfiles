-- Zoom
return {
  'nyngwang/NeoZoom.lua',
  enabled = true,
  config = function()
    vim.keymap.set('n', '<leader><leader>', function()
      vim.cmd 'NeoZoomToggle'
    end, { silent = true, nowait = true, })
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
